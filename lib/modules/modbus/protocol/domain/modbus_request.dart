import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/function_code.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_address.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_limits.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';

const _listEquality = ListEquality<Object>();

/// A validated Modbus request. Constructors throw [ArgumentError]/
/// [RangeError] for values the protocol cannot express, so invalid user
/// input never reaches the wire.
@immutable
sealed class ModbusRequest {
  const new();

  FunctionCode get functionCode;

  bool get isWrite => functionCode.isWrite;
}

final class ReadBitsRequest extends ModbusRequest {
  new({required this.table, required this.address, required this.count}) {
    if (!table.isBitTable) {
      throw ArgumentError.value(table, 'table', 'must be a bit table');
    }
    _checkQuantity(count, ModbusLimits.maxReadBits, 'count');
    ModbusAddress.checkRange(address, count);
  }

  final RegisterTable table;
  final int address;
  final int count;

  @override
  FunctionCode get functionCode => table == RegisterTable.coils
      ? FunctionCode.readCoils
      : FunctionCode.readDiscreteInputs;

  @override
  bool operator ==(Object other) =>
      other is ReadBitsRequest &&
      other.table == table &&
      other.address == address &&
      other.count == count;

  @override
  int get hashCode => Object.hash(table, address, count);
}

final class ReadRegistersRequest extends ModbusRequest {
  new({required this.table, required this.address, required this.count}) {
    if (table.isBitTable) {
      throw ArgumentError.value(table, 'table', 'must be a register table');
    }
    _checkQuantity(count, ModbusLimits.maxReadRegisters, 'count');
    ModbusAddress.checkRange(address, count);
  }

  final RegisterTable table;
  final int address;
  final int count;

  @override
  FunctionCode get functionCode => table == RegisterTable.holdingRegisters
      ? FunctionCode.readHoldingRegisters
      : FunctionCode.readInputRegisters;

  @override
  bool operator ==(Object other) =>
      other is ReadRegistersRequest &&
      other.table == table &&
      other.address == address &&
      other.count == count;

  @override
  int get hashCode => Object.hash(table, address, count);
}

final class WriteSingleCoilRequest extends ModbusRequest {
  new({required this.address, required this.value}) {
    ModbusAddress.checkRange(address, 1);
  }

  final int address;
  final bool value;

  @override
  FunctionCode get functionCode => FunctionCode.writeSingleCoil;

  @override
  bool operator ==(Object other) =>
      other is WriteSingleCoilRequest &&
      other.address == address &&
      other.value == value;

  @override
  int get hashCode => Object.hash(address, value);
}

final class WriteSingleRegisterRequest extends ModbusRequest {
  new({required this.address, required this.value}) {
    ModbusAddress.checkRange(address, 1);
    _checkRegister(value, 'value');
  }

  final int address;
  final int value;

  @override
  FunctionCode get functionCode => FunctionCode.writeSingleRegister;

  @override
  bool operator ==(Object other) =>
      other is WriteSingleRegisterRequest &&
      other.address == address &&
      other.value == value;

  @override
  int get hashCode => Object.hash(address, value);
}

final class WriteMultipleCoilsRequest extends ModbusRequest {
  new({required this.address, required List<bool> values})
    : values = List.unmodifiable(values) {
    _checkQuantity(values.length, ModbusLimits.maxWriteCoils, 'values');
    ModbusAddress.checkRange(address, values.length);
  }

  final int address;
  final List<bool> values;

  @override
  FunctionCode get functionCode => FunctionCode.writeMultipleCoils;

  @override
  bool operator ==(Object other) =>
      other is WriteMultipleCoilsRequest &&
      other.address == address &&
      _listEquality.equals(other.values, values);

  @override
  int get hashCode => Object.hash(address, _listEquality.hash(values));
}

final class WriteMultipleRegistersRequest extends ModbusRequest {
  new({required this.address, required List<int> values})
    : values = List.unmodifiable(values) {
    _checkQuantity(values.length, ModbusLimits.maxWriteRegisters, 'values');
    ModbusAddress.checkRange(address, values.length);
    values.forEach(_checkRegisterValue);
  }

  final int address;
  final List<int> values;

  @override
  FunctionCode get functionCode => FunctionCode.writeMultipleRegisters;

  @override
  bool operator ==(Object other) =>
      other is WriteMultipleRegistersRequest &&
      other.address == address &&
      _listEquality.equals(other.values, values);

  @override
  int get hashCode => Object.hash(address, _listEquality.hash(values));
}

/// FC22: `result = (current AND andMask) OR (orMask AND NOT andMask)`.
final class MaskWriteRegisterRequest extends ModbusRequest {
  new({required this.address, required this.andMask, required this.orMask}) {
    ModbusAddress.checkRange(address, 1);
    _checkRegister(andMask, 'andMask');
    _checkRegister(orMask, 'orMask');
  }

  final int address;
  final int andMask;
  final int orMask;

  @override
  FunctionCode get functionCode => FunctionCode.maskWriteRegister;

  @override
  bool operator ==(Object other) =>
      other is MaskWriteRegisterRequest &&
      other.address == address &&
      other.andMask == andMask &&
      other.orMask == orMask;

  @override
  int get hashCode => Object.hash(address, andMask, orMask);
}

/// FC23: the write is performed before the read.
final class ReadWriteMultipleRegistersRequest extends ModbusRequest {
  new({
    required this.readAddress,
    required this.readCount,
    required this.writeAddress,
    required List<int> writeValues,
  }) : writeValues = List.unmodifiable(writeValues) {
    _checkQuantity(
      readCount,
      ModbusLimits.maxReadWriteReadRegisters,
      'readCount',
    );
    _checkQuantity(
      writeValues.length,
      ModbusLimits.maxReadWriteWriteRegisters,
      'writeValues',
    );
    ModbusAddress.checkRange(readAddress, readCount);
    ModbusAddress.checkRange(writeAddress, writeValues.length);
    writeValues.forEach(_checkRegisterValue);
  }

  final int readAddress;
  final int readCount;
  final int writeAddress;
  final List<int> writeValues;

  @override
  FunctionCode get functionCode => FunctionCode.readWriteMultipleRegisters;

  @override
  bool operator ==(Object other) =>
      other is ReadWriteMultipleRegistersRequest &&
      other.readAddress == readAddress &&
      other.readCount == readCount &&
      other.writeAddress == writeAddress &&
      _listEquality.equals(other.writeValues, writeValues);

  @override
  int get hashCode => Object.hash(
    readAddress,
    readCount,
    writeAddress,
    _listEquality.hash(writeValues),
  );
}

/// Read Device ID code of FC43/MEI 14.
enum DeviceIdCategory {
  basic(0x01),
  regular(0x02),
  extended(0x03),
  individual(0x04);

  new(this.code);

  final int code;

  static DeviceIdCategory? fromCode(int code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

final class ReadDeviceIdentificationRequest extends ModbusRequest {
  new({this.category = DeviceIdCategory.basic, this.objectId = 0}) {
    RangeError.checkValueInInterval(objectId, 0, 0xFF, 'objectId');
  }

  /// MEI type for "Read Device Identification".
  static const meiType = 0x0E;

  final DeviceIdCategory category;
  final int objectId;

  @override
  FunctionCode get functionCode => FunctionCode.encapsulatedInterface;

  @override
  bool operator ==(Object other) =>
      other is ReadDeviceIdentificationRequest &&
      other.category == category &&
      other.objectId == objectId;

  @override
  int get hashCode => Object.hash(category, objectId);
}

void _checkQuantity(int value, int max, String name) =>
    RangeError.checkValueInInterval(value, 1, max, name);

void _checkRegister(int value, String name) =>
    RangeError.checkValueInInterval(value, 0, 0xFFFF, name);

void _checkRegisterValue(int value) => _checkRegister(value, 'values');
