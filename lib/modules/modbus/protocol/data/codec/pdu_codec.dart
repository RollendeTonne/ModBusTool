import 'dart:typed_data';

import 'package:modbus_explorer/modules/modbus/protocol/data/codec/byte_io.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/function_code.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_errors.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_limits.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_request.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_response.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';

const _coilOn = 0xFF00;
const _coilOff = 0x0000;
const _addressSpace = 0x10000;

/// Server-side decode failure, answered with an exception response.
final class RequestRejected implements Exception {
  const new(this.code, this.message);

  final ModbusExceptionCode code;
  final String message;

  @override
  String toString() => 'RequestRejected(${code.specName}: $message)';
}

/// Encodes/decodes PDUs (function code + data) for both client and server.
abstract final class PduCodec {
  // ---------------------------------------------------------------- client

  static Uint8List encodeRequest(ModbusRequest request) {
    final w = PduWriter()..u8(request.functionCode.code);
    switch (request) {
      case ReadBitsRequest(:final address, :final count) ||
          ReadRegistersRequest(:final address, :final count):
        w
          ..u16(address)
          ..u16(count);
      case WriteSingleCoilRequest(:final address, :final value):
        w
          ..u16(address)
          ..u16(value ? _coilOn : _coilOff);
      case WriteSingleRegisterRequest(:final address, :final value):
        w
          ..u16(address)
          ..u16(value);
      case WriteMultipleCoilsRequest(:final address, :final values):
        final packed = packBits(values);
        w
          ..u16(address)
          ..u16(values.length)
          ..u8(packed.length)
          ..bytes(packed);
      case WriteMultipleRegistersRequest(:final address, :final values):
        w
          ..u16(address)
          ..u16(values.length)
          ..u8(values.length * 2)
          ..registers(values);
      case MaskWriteRegisterRequest(
        :final address,
        :final andMask,
        :final orMask,
      ):
        w
          ..u16(address)
          ..u16(andMask)
          ..u16(orMask);
      case ReadWriteMultipleRegistersRequest():
        w
          ..u16(request.readAddress)
          ..u16(request.readCount)
          ..u16(request.writeAddress)
          ..u16(request.writeValues.length)
          ..u8(request.writeValues.length * 2)
          ..registers(request.writeValues);
      case ReadDeviceIdentificationRequest(:final category, :final objectId):
        w
          ..u8(ReadDeviceIdentificationRequest.meiType)
          ..u8(category.code)
          ..u8(objectId);
    }
    return w.take();
  }

  /// Decodes and validates [pdu] as the answer to [request].
  ///
  /// Exception PDUs become [ExceptionResponse]; anything inconsistent with
  /// the request throws [ModbusProtocolException].
  static ModbusResponse decodeResponse(ModbusRequest request, List<int> pdu) {
    final frame = Uint8List.fromList(pdu);
    if (pdu.isEmpty) {
      throw ModbusProtocolException('Empty response PDU', frame: frame);
    }
    final expectedFc = request.functionCode.code;
    final fc = pdu[0];
    if (fc == expectedFc | FunctionCode.exceptionFlag) {
      if (pdu.length != 2) {
        throw ModbusProtocolException(
          'Exception response must be 2 bytes, got ${pdu.length}',
          frame: frame,
        );
      }
      return ExceptionResponse(functionCode: expectedFc, exceptionCode: pdu[1]);
    }
    if (fc != expectedFc) {
      throw ModbusProtocolException(
        'Expected function code 0x${_hex(expectedFc)}, got 0x${_hex(fc)}',
        frame: frame,
      );
    }
    try {
      final response = _decodeResponseData(request, PduReader(pdu, 1));
      return response;
    } on PduFormatException catch (e) {
      throw ModbusProtocolException(e.message, frame: frame);
    }
  }

  static ModbusResponse _decodeResponseData(
    ModbusRequest request,
    PduReader r,
  ) {
    switch (request) {
      case ReadBitsRequest(:final count):
        final byteCount = r.u8();
        _expect(byteCount == (count + 7) >> 3, 'byte count', byteCount);
        final bits = unpackBits(r.bytes(byteCount), count);
        r.expectEnd();
        return ReadBitsResponse(bits);
      case ReadRegistersRequest(:final count) ||
          ReadWriteMultipleRegistersRequest(readCount: final count):
        final byteCount = r.u8();
        _expect(byteCount == count * 2, 'byte count', byteCount);
        final values = r.registers(count);
        r.expectEnd();
        return ReadRegistersResponse(values);
      case WriteSingleCoilRequest(:final address, :final value):
        _expectEcho(r, [address, if (value) _coilOn else _coilOff]);
      case WriteSingleRegisterRequest(:final address, :final value):
        _expectEcho(r, [address, value]);
      case WriteMultipleCoilsRequest(:final address, :final values):
        _expectEcho(r, [address, values.length]);
      case WriteMultipleRegistersRequest(:final address, :final values):
        _expectEcho(r, [address, values.length]);
      case MaskWriteRegisterRequest(
        :final address,
        :final andMask,
        :final orMask,
      ):
        _expectEcho(r, [address, andMask, orMask]);
      case ReadDeviceIdentificationRequest():
        return _decodeDeviceId(request, r);
    }
    return const WriteAcknowledgedResponse();
  }

  static DeviceIdentificationResponse _decodeDeviceId(
    ReadDeviceIdentificationRequest request,
    PduReader r,
  ) {
    final mei = r.u8();
    _expect(mei == ReadDeviceIdentificationRequest.meiType, 'MEI type', mei);
    final categoryCode = r.u8();
    final conformity = r.u8();
    final moreFollows = r.u8();
    final nextObjectId = r.u8();
    final objectCount = r.u8();
    final objects = <int, List<int>>{};
    for (var i = 0; i < objectCount; i++) {
      final id = r.u8();
      final length = r.u8();
      objects[id] = r.bytes(length);
    }
    r.expectEnd();
    return DeviceIdentificationResponse(
      category: DeviceIdCategory.fromCode(categoryCode) ?? request.category,
      conformityLevel: conformity,
      moreFollows: moreFollows == 0xFF,
      nextObjectId: nextObjectId,
      objects: objects,
    );
  }

  static void _expectEcho(PduReader r, List<int> expected) {
    final actual = [for (final _ in expected) r.u16()];
    r.expectEnd();
    for (var i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) {
        throw PduFormatException(
          'Echo mismatch: expected ${expected.map(_hex4).join(' ')}, '
          'got ${actual.map(_hex4).join(' ')}',
        );
      }
    }
  }

  static void _expect(bool condition, String field, int actual) {
    if (!condition) throw PduFormatException('Unexpected $field $actual');
  }

  // ---------------------------------------------------------------- server

  /// Parses a request PDU on the server side.
  ///
  /// Throws [RequestRejected] with the exception code a compliant device
  /// would return.
  static ModbusRequest decodeRequest(List<int> pdu) {
    if (pdu.isEmpty) {
      throw const RequestRejected(
        ModbusExceptionCode.illegalFunction,
        'empty PDU',
      );
    }
    final fc = FunctionCode.fromCode(pdu[0]);
    if (fc == null) {
      throw RequestRejected(
        ModbusExceptionCode.illegalFunction,
        'unsupported function 0x${_hex(pdu[0])}',
      );
    }
    final r = PduReader(pdu, 1);
    try {
      final request = _decodeRequestData(fc, r);
      r.expectEnd();
      return request;
    } on PduFormatException catch (e) {
      throw RequestRejected(ModbusExceptionCode.illegalDataValue, e.message);
    }
  }

  static ModbusRequest _decodeRequestData(FunctionCode fc, PduReader r) {
    switch (fc) {
      case FunctionCode.readCoils || FunctionCode.readDiscreteInputs:
        final address = r.u16();
        final count = r.u16();
        _checkQuantity(count, ModbusLimits.maxReadBits);
        _checkAddress(address, count);
        return ReadBitsRequest(
          table: fc == FunctionCode.readCoils
              ? RegisterTable.coils
              : RegisterTable.discreteInputs,
          address: address,
          count: count,
        );
      case FunctionCode.readHoldingRegisters || FunctionCode.readInputRegisters:
        final address = r.u16();
        final count = r.u16();
        _checkQuantity(count, ModbusLimits.maxReadRegisters);
        _checkAddress(address, count);
        return ReadRegistersRequest(
          table: fc == FunctionCode.readHoldingRegisters
              ? RegisterTable.holdingRegisters
              : RegisterTable.inputRegisters,
          address: address,
          count: count,
        );
      case FunctionCode.writeSingleCoil:
        final address = r.u16();
        final value = r.u16();
        if (value != _coilOn && value != _coilOff) {
          throw RequestRejected(
            ModbusExceptionCode.illegalDataValue,
            'coil value must be 0x0000 or 0xFF00, got 0x${_hex4(value)}',
          );
        }
        return WriteSingleCoilRequest(
          address: address,
          value: value == _coilOn,
        );
      case FunctionCode.writeSingleRegister:
        return WriteSingleRegisterRequest(address: r.u16(), value: r.u16());
      case FunctionCode.writeMultipleCoils:
        final address = r.u16();
        final count = r.u16();
        final byteCount = r.u8();
        _checkQuantity(count, ModbusLimits.maxWriteCoils);
        _checkByteCount(byteCount, (count + 7) >> 3);
        _checkAddress(address, count);
        return WriteMultipleCoilsRequest(
          address: address,
          values: unpackBits(r.bytes(byteCount), count),
        );
      case FunctionCode.writeMultipleRegisters:
        final address = r.u16();
        final count = r.u16();
        final byteCount = r.u8();
        _checkQuantity(count, ModbusLimits.maxWriteRegisters);
        _checkByteCount(byteCount, count * 2);
        _checkAddress(address, count);
        return WriteMultipleRegistersRequest(
          address: address,
          values: r.registers(count),
        );
      case FunctionCode.maskWriteRegister:
        return MaskWriteRegisterRequest(
          address: r.u16(),
          andMask: r.u16(),
          orMask: r.u16(),
        );
      case FunctionCode.readWriteMultipleRegisters:
        final readAddress = r.u16();
        final readCount = r.u16();
        final writeAddress = r.u16();
        final writeCount = r.u16();
        final byteCount = r.u8();
        _checkQuantity(readCount, ModbusLimits.maxReadWriteReadRegisters);
        _checkQuantity(writeCount, ModbusLimits.maxReadWriteWriteRegisters);
        _checkByteCount(byteCount, writeCount * 2);
        _checkAddress(readAddress, readCount);
        _checkAddress(writeAddress, writeCount);
        return ReadWriteMultipleRegistersRequest(
          readAddress: readAddress,
          readCount: readCount,
          writeAddress: writeAddress,
          writeValues: r.registers(writeCount),
        );
      case FunctionCode.encapsulatedInterface:
        final mei = r.u8();
        if (mei != ReadDeviceIdentificationRequest.meiType) {
          throw RequestRejected(
            ModbusExceptionCode.illegalFunction,
            'unsupported MEI type 0x${_hex(mei)}',
          );
        }
        final categoryCode = r.u8();
        final category = DeviceIdCategory.fromCode(categoryCode);
        if (category == null) {
          throw RequestRejected(
            ModbusExceptionCode.illegalDataValue,
            'invalid Read Device ID code $categoryCode',
          );
        }
        return ReadDeviceIdentificationRequest(
          category: category,
          objectId: r.u8(),
        );
    }
  }

  static Uint8List encodeResponse(
    ModbusRequest request,
    ModbusResponse response,
  ) {
    final fc = request.functionCode.code;
    final w = PduWriter();
    switch (response) {
      case ExceptionResponse(:final exceptionCode):
        return encodeException(fc, exceptionCode);
      case ReadBitsResponse(:final values):
        final packed = packBits(values);
        w
          ..u8(fc)
          ..u8(packed.length)
          ..bytes(packed);
      case ReadRegistersResponse(:final values):
        w
          ..u8(fc)
          ..u8(values.length * 2)
          ..registers(values);
      case WriteAcknowledgedResponse():
        // Write responses echo the request header (single writes: the
        // complete request; multiple writes: address and quantity).
        final encoded = encodeRequest(request);
        final echoLength = switch (request) {
          WriteMultipleCoilsRequest() || WriteMultipleRegistersRequest() => 5,
          _ => encoded.length,
        };
        w.bytes(encoded.sublist(0, echoLength));
      case DeviceIdentificationResponse():
        w
          ..u8(fc)
          ..u8(ReadDeviceIdentificationRequest.meiType)
          ..u8(response.category.code)
          ..u8(response.conformityLevel)
          ..u8(response.moreFollows ? 0xFF : 0x00)
          ..u8(response.nextObjectId)
          ..u8(response.objects.length);
        for (final MapEntry(key: id, value: bytes)
            in response.objects.entries) {
          w
            ..u8(id)
            ..u8(bytes.length)
            ..bytes(bytes);
        }
      case NoResponseExpected():
        throw ArgumentError('NoResponseExpected has no PDU');
    }
    return w.take();
  }

  static Uint8List encodeException(int functionCode, int exceptionCode) =>
      Uint8List.fromList([
        (functionCode | FunctionCode.exceptionFlag) & 0xFF,
        exceptionCode,
      ]);

  static void _checkQuantity(int count, int max) {
    if (count < 1 || count > max) {
      throw RequestRejected(
        ModbusExceptionCode.illegalDataValue,
        'quantity $count outside 1..$max',
      );
    }
  }

  static void _checkByteCount(int actual, int expected) {
    if (actual != expected) {
      throw RequestRejected(
        ModbusExceptionCode.illegalDataValue,
        'byte count $actual, expected $expected',
      );
    }
  }

  static void _checkAddress(int address, int count) {
    if (address + count > _addressSpace) {
      throw RequestRejected(
        ModbusExceptionCode.illegalDataAddress,
        'range $address+$count exceeds address space',
      );
    }
  }

  static String _hex(int v) =>
      v.toRadixString(16).toUpperCase().padLeft(2, '0');
  static String _hex4(int v) =>
      v.toRadixString(16).toUpperCase().padLeft(4, '0');
}
