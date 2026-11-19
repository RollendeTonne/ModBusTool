import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_exception_code.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_request.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_response.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';

/// Address range that always answers with an exception, to demonstrate and
/// test error handling.
@immutable
final class SimulatedFaultRange {
  const new({
    required this.table,
    required this.start,
    required this.end,
    required this.code,
  });

  final RegisterTable table;
  final int start;

  /// Inclusive.
  final int end;
  final ModbusExceptionCode code;

  bool overlaps(RegisterTable t, int address, int count) =>
      t == table && address <= end && address + count - 1 >= start;
}

/// In-memory Modbus server data model with spec-conform validation.
final class SimulatedDevice {
  new({
    this.size = 2000,
    Map<int, String> identification = const {},
    this.faultRanges = const [],
  }) : coils = Uint8List(size),
       discreteInputs = Uint8List(size),
       holdingRegisters = Uint16List(size),
       inputRegisters = Uint16List(size),
       identification = {
         for (final MapEntry(:key, :value) in identification.entries)
           key: value.codeUnits,
       };

  /// Addresses `>= size` answer ILLEGAL DATA ADDRESS.
  final int size;
  final Uint8List coils;
  final Uint8List discreteInputs;
  final Uint16List holdingRegisters;
  final Uint16List inputRegisters;
  final Map<int, List<int>> identification;
  final List<SimulatedFaultRange> faultRanges;

  void setRegisters(RegisterTable table, int address, List<int> values) {
    (table == RegisterTable.holdingRegisters
            ? holdingRegisters
            : inputRegisters)
        .setAll(address, values);
  }

  void setBits(RegisterTable table, int address, List<bool> values) {
    (table == RegisterTable.coils ? coils : discreteInputs).setAll(
      address,
      values.map((b) => b ? 1 : 0),
    );
  }

  ModbusResponse handle(ModbusRequest request) {
    ExceptionResponse exception(ModbusExceptionCode code) => ExceptionResponse(
      functionCode: request.functionCode.code,
      exceptionCode: code.code,
    );

    ModbusExceptionCode? check(RegisterTable table, int address, int count) {
      if (address + count > size) {
        return ModbusExceptionCode.illegalDataAddress;
      }
      for (final fault in faultRanges) {
        if (fault.overlaps(table, address, count)) return fault.code;
      }
      return null;
    }

    switch (request) {
      case ReadBitsRequest(:final table, :final address, :final count):
        if (check(table, address, count) case final code?) {
          return exception(code);
        }
        final source = table == RegisterTable.coils ? coils : discreteInputs;
        return ReadBitsResponse([
          for (var i = 0; i < count; i++) source[address + i] != 0,
        ]);
      case ReadRegistersRequest(:final table, :final address, :final count):
        if (check(table, address, count) case final code?) {
          return exception(code);
        }
        final source = table == RegisterTable.holdingRegisters
            ? holdingRegisters
            : inputRegisters;
        return ReadRegistersResponse(source.sublist(address, address + count));
      case WriteSingleCoilRequest(:final address, :final value):
        if (check(RegisterTable.coils, address, 1) case final code?) {
          return exception(code);
        }
        coils[address] = value ? 1 : 0;
      case WriteSingleRegisterRequest(:final address, :final value):
        if (check(RegisterTable.holdingRegisters, address, 1)
            case final code?) {
          return exception(code);
        }
        holdingRegisters[address] = value;
      case WriteMultipleCoilsRequest(:final address, :final values):
        if (check(RegisterTable.coils, address, values.length)
            case final code?) {
          return exception(code);
        }
        setBits(RegisterTable.coils, address, values);
      case WriteMultipleRegistersRequest(:final address, :final values):
        if (check(RegisterTable.holdingRegisters, address, values.length)
            case final code?) {
          return exception(code);
        }
        holdingRegisters.setAll(address, values);
      case MaskWriteRegisterRequest(
        :final address,
        :final andMask,
        :final orMask,
      ):
        if (check(RegisterTable.holdingRegisters, address, 1)
            case final code?) {
          return exception(code);
        }
        final current = holdingRegisters[address];
        holdingRegisters[address] =
            (current & andMask) | (orMask & ~andMask & 0xFFFF);
      case ReadWriteMultipleRegistersRequest():
        final writeCode = check(
          RegisterTable.holdingRegisters,
          request.writeAddress,
          request.writeValues.length,
        );
        final readCode = check(
          RegisterTable.holdingRegisters,
          request.readAddress,
          request.readCount,
        );
        if (writeCode ?? readCode case final code?) return exception(code);
        // Spec: the write is performed before the read.
        holdingRegisters.setAll(request.writeAddress, request.writeValues);
        return ReadRegistersResponse(
          holdingRegisters.sublist(
            request.readAddress,
            request.readAddress + request.readCount,
          ),
        );
      case ReadDeviceIdentificationRequest():
        return _deviceIdentification(request) ??
            exception(ModbusExceptionCode.illegalDataAddress);
    }
    return const WriteAcknowledgedResponse();
  }

  DeviceIdentificationResponse? _deviceIdentification(
    ReadDeviceIdentificationRequest request,
  ) {
    final ids = identification.keys.toList()..sort();
    final selected = switch (request.category) {
      DeviceIdCategory.basic => ids.where((id) => id <= 0x02),
      DeviceIdCategory.regular => ids.where((id) => id <= 0x7F),
      DeviceIdCategory.extended => ids,
      DeviceIdCategory.individual => ids.where((id) => id == request.objectId),
    }.where((id) => id >= request.objectId).toList();
    if (selected.isEmpty) return null;
    final hasExtended = ids.any((id) => id >= 0x80);
    return DeviceIdentificationResponse(
      category: request.category,
      // 0x80 = individual access supported; low bits = highest category.
      conformityLevel: 0x80 | (hasExtended ? 0x03 : 0x02),
      moreFollows: false,
      nextObjectId: 0,
      objects: {for (final id in selected) id: identification[id]!},
    );
  }
}
