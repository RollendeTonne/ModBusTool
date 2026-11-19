import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/features/modbus/data/codec/pdu_codec.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_response.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';

import '../../helpers/hex.dart';

// Examples from the Modbus Application Protocol Specification V1.1b3.
final readCoils = ReadBitsRequest(
  table: RegisterTable.coils,
  address: 0x13,
  count: 19,
);
final readHolding = ReadRegistersRequest(
  table: RegisterTable.holdingRegisters,
  address: 0x6B,
  count: 3,
);
final writeCoil = WriteSingleCoilRequest(address: 0xAC, value: true);
final writeRegister = WriteSingleRegisterRequest(address: 1, value: 3);
final writeCoils = WriteMultipleCoilsRequest(
  address: 0x13,
  values: const [
    true, false, true, true, false, false, true, true, // CD
    true, false, // 01
  ],
);
final writeRegisters = WriteMultipleRegistersRequest(
  address: 1,
  values: const [0x000A, 0x0102],
);
final maskWrite = MaskWriteRegisterRequest(
  address: 4,
  andMask: 0xF2,
  orMask: 0x25,
);
final readWrite = ReadWriteMultipleRegistersRequest(
  readAddress: 3,
  readCount: 6,
  writeAddress: 0x0E,
  writeValues: const [0xFF, 0xFF, 0xFF],
);
final deviceId = ReadDeviceIdentificationRequest();

void main() {
  group('encodeRequest (spec examples)', () {
    final cases = <String, (ModbusRequest, String)>{
      'FC01': (readCoils, '01 00 13 00 13'),
      'FC03': (readHolding, '03 00 6B 00 03'),
      'FC05': (writeCoil, '05 00 AC FF 00'),
      'FC05 off': (
        WriteSingleCoilRequest(address: 1, value: false),
        '05 00 01 00 00',
      ),
      'FC06': (writeRegister, '06 00 01 00 03'),
      'FC15': (writeCoils, '0F 00 13 00 0A 02 CD 01'),
      'FC16': (writeRegisters, '10 00 01 00 02 04 00 0A 01 02'),
      'FC22': (maskWrite, '16 00 04 00 F2 00 25'),
      'FC23': (readWrite, '17 00 03 00 06 00 0E 00 03 06 00 FF 00 FF 00 FF'),
      'FC43/14': (deviceId, '2B 0E 01 00'),
    };
    for (final MapEntry(key: name, value: (request, expected))
        in cases.entries) {
      test(name, () {
        expect(PduCodec.encodeRequest(request), hex(expected));
      });
    }
  });

  group('decodeResponse', () {
    test('FC01 bits are LSB first (spec example CD 6B 05)', () {
      final response = PduCodec.decodeResponse(
        readCoils,
        hex('01 03 CD 6B 05'),
      );
      final bits = (response as ReadBitsResponse).values;
      expect(bits, hasLength(19));
      // 0xCD = 1100 1101 → coils 20..27 = 1,0,1,1,0,0,1,1
      expect(bits.sublist(0, 8), [
        true,
        false,
        true,
        true,
        false,
        false,
        true,
        true,
      ]);
      // 0x05 → coils 36..38 = 1,0,1
      expect(bits.sublist(16), [true, false, true]);
    });

    test('FC03 registers (spec example)', () {
      final response = PduCodec.decodeResponse(
        readHolding,
        hex('03 06 02 2B 00 00 00 64'),
      );
      expect((response as ReadRegistersResponse).values, [0x022B, 0, 0x64]);
    });

    test('FC23 returns read registers', () {
      final response = PduCodec.decodeResponse(
        readWrite,
        hex('17 0C 00 FE 0A CD 00 01 00 03 00 0D 00 FF'),
      );
      expect((response as ReadRegistersResponse).values, hasLength(6));
    });

    test('write echoes are verified', () {
      expect(
        PduCodec.decodeResponse(writeCoil, hex('05 00 AC FF 00')),
        const WriteAcknowledgedResponse(),
      );
      expect(
        PduCodec.decodeResponse(writeRegisters, hex('10 00 01 00 02')),
        const WriteAcknowledgedResponse(),
      );
      expect(
        PduCodec.decodeResponse(maskWrite, hex('16 00 04 00 F2 00 25')),
        const WriteAcknowledgedResponse(),
      );
    });

    test('device identification objects', () {
      final response = PduCodec.decodeResponse(
        deviceId,
        hex(
          '2B 0E 01 81 00 00 03 '
          '00 03 41 42 43 01 02 50 31 02 03 31 2E 30',
        ),
      );
      response as DeviceIdentificationResponse;
      expect(response.text(DeviceIdObject.vendorName), 'ABC');
      expect(response.text(DeviceIdObject.productCode), 'P1');
      expect(response.text(DeviceIdObject.majorMinorRevision), '1.0');
      expect(response.conformityLevel, 0x81);
      expect(response.moreFollows, isFalse);
    });

    test('exception response', () {
      expect(
        PduCodec.decodeResponse(readHolding, hex('83 02')),
        const ExceptionResponse(functionCode: 3, exceptionCode: 2),
      );
      expect(
        const ExceptionResponse(functionCode: 3, exceptionCode: 2).code,
        ModbusExceptionCode.illegalDataAddress,
      );
    });

    final malformed = <String, (ModbusRequest, String)>{
      'empty': (readHolding, ''),
      'wrong function code': (readHolding, '04 06 00 00 00 00 00 00'),
      'byte count mismatch': (readHolding, '03 04 00 00 00 00'),
      'truncated data': (readHolding, '03 06 00 00 00'),
      'trailing bytes': (readHolding, '03 06 00 00 00 00 00 00 FF'),
      'bit byte count': (readCoils, '01 02 CD 6B'),
      'echo address mismatch': (writeRegister, '06 00 02 00 03'),
      'echo value mismatch': (writeCoil, '05 00 AC 00 00'),
      'multiple write count mismatch': (writeRegisters, '10 00 01 00 03'),
      'exception too long': (readHolding, '83 02 00'),
      'device id wrong MEI': (deviceId, '2B 0D 01 81 00 00 00'),
      'device id truncated object': (deviceId, '2B 0E 01 81 00 00 01 00 05 41'),
    };
    for (final MapEntry(key: name, value: (request, pdu))
        in malformed.entries) {
      test('rejects $name', () {
        expect(
          () => PduCodec.decodeResponse(request, hex(pdu)),
          throwsA(isA<ModbusProtocolException>()),
        );
      });
    }
  });

  group('request validation', () {
    test('quantity limits', () {
      expect(
        () => ReadRegistersRequest(
          table: RegisterTable.holdingRegisters,
          address: 0,
          count: 126,
        ),
        throwsRangeError,
      );
      expect(
        () => ReadBitsRequest(table: RegisterTable.coils, address: 0, count: 0),
        throwsRangeError,
      );
      expect(
        () => WriteMultipleRegistersRequest(
          address: 0,
          values: List.filled(124, 0),
        ),
        throwsRangeError,
      );
      expect(
        () => WriteMultipleCoilsRequest(
          address: 0,
          values: List.filled(1969, true),
        ),
        throwsRangeError,
      );
    });

    test('address overflow and register range', () {
      expect(
        () => ReadRegistersRequest(
          table: RegisterTable.inputRegisters,
          address: 65535,
          count: 2,
        ),
        throwsRangeError,
      );
      expect(
        () => WriteSingleRegisterRequest(address: 0, value: 0x10000),
        throwsRangeError,
      );
      expect(
        () => WriteMultipleRegistersRequest(address: 0, values: const [-1]),
        throwsRangeError,
      );
    });

    test('table must match the request kind', () {
      expect(
        () => ReadBitsRequest(
          table: RegisterTable.holdingRegisters,
          address: 0,
          count: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => ReadRegistersRequest(
          table: RegisterTable.coils,
          address: 0,
          count: 1,
        ),
        throwsArgumentError,
      );
    });

    test('isWrite', () {
      expect(readHolding.isWrite, isFalse);
      expect(writeCoil.isWrite, isTrue);
      expect(readWrite.isWrite, isTrue);
    });
  });

  group('server side', () {
    final requests = <ModbusRequest>[
      readCoils,
      ReadBitsRequest(
        table: RegisterTable.discreteInputs,
        address: 5,
        count: 2000,
      ),
      readHolding,
      ReadRegistersRequest(
        table: RegisterTable.inputRegisters,
        address: 0,
        count: 125,
      ),
      writeCoil,
      writeRegister,
      writeCoils,
      writeRegisters,
      maskWrite,
      readWrite,
      deviceId,
    ];
    for (final request in requests) {
      test('decodeRequest round-trips ${request.functionCode.label}', () {
        expect(
          PduCodec.decodeRequest(PduCodec.encodeRequest(request)),
          request,
        );
      });
    }

    final responses = <(ModbusRequest, ModbusResponse)>[
      (readCoils, ReadBitsResponse(List.generate(19, (i) => i.isOdd))),
      (readHolding, ReadRegistersResponse(const [1, 2, 0xFFFF])),
      (writeCoil, const WriteAcknowledgedResponse()),
      (writeRegister, const WriteAcknowledgedResponse()),
      (writeCoils, const WriteAcknowledgedResponse()),
      (writeRegisters, const WriteAcknowledgedResponse()),
      (maskWrite, const WriteAcknowledgedResponse()),
      (readWrite, ReadRegistersResponse(const [1, 2, 3, 4, 5, 6])),
      (
        deviceId,
        DeviceIdentificationResponse(
          category: DeviceIdCategory.basic,
          conformityLevel: 0x82,
          moreFollows: false,
          nextObjectId: 0,
          objects: {0: 'Vendor'.codeUnits, 1: 'P'.codeUnits},
        ),
      ),
      (readHolding, const ExceptionResponse(functionCode: 3, exceptionCode: 4)),
    ];
    for (final (request, response) in responses) {
      test('encodeResponse → decodeResponse for ${response.runtimeType} '
          '(${request.functionCode.label})', () {
        final pdu = PduCodec.encodeResponse(request, response);
        expect(PduCodec.decodeResponse(request, pdu), response);
      });
    }

    test('write multiple response echoes only address and quantity', () {
      expect(
        PduCodec.encodeResponse(
          writeRegisters,
          const WriteAcknowledgedResponse(),
        ),
        hex('10 00 01 00 02'),
      );
    });

    final rejected = <String, (String, ModbusExceptionCode)>{
      'unknown function': ('07', ModbusExceptionCode.illegalFunction),
      'empty': ('', ModbusExceptionCode.illegalFunction),
      'quantity 0': ('03 00 00 00 00', ModbusExceptionCode.illegalDataValue),
      'quantity 126': ('03 00 00 00 7E', ModbusExceptionCode.illegalDataValue),
      'address overflow': (
        '03 FF FF 00 02',
        ModbusExceptionCode.illegalDataAddress,
      ),
      'invalid coil value': (
        '05 00 01 12 34',
        ModbusExceptionCode.illegalDataValue,
      ),
      'byte count mismatch': (
        '10 00 01 00 02 03 00 0A 01',
        ModbusExceptionCode.illegalDataValue,
      ),
      'truncated': ('03 00 00', ModbusExceptionCode.illegalDataValue),
      'trailing': ('06 00 01 00 03 FF', ModbusExceptionCode.illegalDataValue),
      'unsupported MEI': ('2B 0D 01 00', ModbusExceptionCode.illegalFunction),
      'invalid device id code': (
        '2B 0E 05 00',
        ModbusExceptionCode.illegalDataValue,
      ),
    };
    for (final MapEntry(key: name, value: (pdu, code)) in rejected.entries) {
      test('decodeRequest rejects $name with ${code.specName}', () {
        expect(
          () => PduCodec.decodeRequest(hex(pdu)),
          throwsA(isA<RequestRejected>().having((e) => e.code, 'code', code)),
        );
      });
    }

    test('encodeException sets the high bit', () {
      expect(PduCodec.encodeException(0x03, 0x02), hex('83 02'));
    });
  });
}
