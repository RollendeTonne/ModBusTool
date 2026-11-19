import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_address.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/shared/interpretation/domain/interpreted_value.dart';
import 'package:modbus_explorer/shared/interpretation/domain/scaling.dart';
import 'package:modbus_explorer/shared/interpretation/domain/text_decoder.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_decoder.dart';

/// How the registers of a map entry are interpreted.
@immutable
sealed class ValueFormat {
  const new();

  int get registerCount;

  bool supports(RegisterTable table);
}

final class NumericFormat extends ValueFormat {
  new(this.type, this.order) {
    if (order.width != type.byteWidth) {
      throw ArgumentError(
        'Byte order ${order.pattern} does not fit ${type.technicalName}',
      );
    }
  }

  final DataType type;
  final ByteOrder order;

  @override
  int get registerCount => type.registerCount;

  @override
  bool supports(RegisterTable table) => !table.isBitTable;

  @override
  bool operator ==(Object other) =>
      other is NumericFormat && other.type == type && other.order == order;

  @override
  int get hashCode => Object.hash(type, order);
}

final class TextFormat extends ValueFormat {
  new({
    required this.registerCount,
    this.swapBytes = false,
    this.encoding = TextEncoding.ascii,
  }) {
    RangeError.checkValueInInterval(
      registerCount,
      1,
      maxRegisters,
      'registerCount',
    );
  }

  /// Longer strings are unusual and would need several requests.
  static const maxRegisters = 64;

  @override
  final int registerCount;
  final bool swapBytes;
  final TextEncoding encoding;

  @override
  bool supports(RegisterTable table) => !table.isBitTable;

  @override
  bool operator ==(Object other) =>
      other is TextFormat &&
      other.registerCount == registerCount &&
      other.swapBytes == swapBytes &&
      other.encoding == encoding;

  @override
  int get hashCode => Object.hash(registerCount, swapBytes, encoding);
}

/// A coil/discrete input (`bit == null`) or one bit of a register.
final class BitFormat extends ValueFormat {
  new({this.bit}) {
    if (bit case final b?) RangeError.checkValueInInterval(b, 0, 15, 'bit');
  }

  final int? bit;

  @override
  int get registerCount => 1;

  @override
  bool supports(RegisterTable table) =>
      table.isBitTable ? bit == null : bit != null;

  @override
  bool operator ==(Object other) => other is BitFormat && other.bit == bit;

  @override
  int get hashCode => bit.hashCode;
}

/// One named value of a device: where it lives and how to read it.
@immutable
final class RegisterMapEntry {
  new({
    required this.id,
    required this.table,
    required this.address,
    required this.format,
    this.label = '',
    this.unit = '',
    this.description = '',
    this.scaling = Scaling.identity,
  }) {
    if (!format.supports(table)) {
      throw ArgumentError('${format.runtimeType} not valid for $table');
    }
    ModbusAddress.checkRange(address, format.registerCount);
  }

  final String id;
  final RegisterTable table;

  /// Protocol (0-based) address of the first register.
  final int address;
  final ValueFormat format;
  final String label;
  final String unit;
  final String description;
  final Scaling scaling;

  int get registerCount => format.registerCount;
  int get lastAddress => address + registerCount - 1;

  bool covers(RegisterTable t, int a) =>
      t == table && a >= address && a <= lastAddress;

  /// Decodes from [values] = register values (or 0/1 bits) starting at
  /// [address].
  InterpretedValue decode(List<int> values) {
    if (values.length < registerCount) {
      return const InvalidValue(InvalidReason.insufficientData);
    }
    return switch (format) {
      NumericFormat(:final type, :final order) => decodeValue(
        registersToBytes(values.sublist(0, registerCount)),
        type,
        order,
      ),
      TextFormat(:final swapBytes, :final encoding) => decodeText(
        registersToBytes(values.sublist(0, registerCount)),
        swapBytes: swapBytes,
        encoding: encoding,
      ),
      BitFormat(:final bit) => BoolValue(
        bit == null ? values.first != 0 : (values.first >> bit) & 1 == 1,
      ),
    };
  }

  RegisterMapEntry copyWith({
    String? id,
    RegisterTable? table,
    int? address,
    ValueFormat? format,
    String? label,
    String? unit,
    String? description,
    Scaling? scaling,
  }) => RegisterMapEntry(
    id: id ?? this.id,
    table: table ?? this.table,
    address: address ?? this.address,
    format: format ?? this.format,
    label: label ?? this.label,
    unit: unit ?? this.unit,
    description: description ?? this.description,
    scaling: scaling ?? this.scaling,
  );

  @override
  bool operator ==(Object other) =>
      other is RegisterMapEntry &&
      other.id == id &&
      other.table == table &&
      other.address == address &&
      other.format == format &&
      other.label == label &&
      other.unit == unit &&
      other.description == description &&
      other.scaling == scaling;

  @override
  int get hashCode => Object.hash(
    id,
    table,
    address,
    format,
    label,
    unit,
    description,
    scaling,
  );
}
