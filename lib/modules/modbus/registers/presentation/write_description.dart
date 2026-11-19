import 'package:modbus_explorer/modules/modbus/protocol/domain/addressing_mode.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_address.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/modbus_request.dart';
import 'package:modbus_explorer/modules/modbus/protocol/domain/register_table.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';

/// Compact, language-neutral summary of a write request for confirmation
/// dialogs and snackbars, e.g. `FC06 · 40001 = 0x002A (42)`.
String describeWrite(ModbusRequest request, AddressingMode mode) {
  String holding(int a) =>
      ModbusAddress.format(a, RegisterTable.holdingRegisters, mode);
  String coil(int a) => ModbusAddress.format(a, RegisterTable.coils, mode);
  String register(int v) => '${formatHex(v)} ($v)';
  String range(String Function(int) format, int start, int count) => count == 1
      ? format(start)
      : '${format(start)}…${format(start + count - 1)}';
  String abbreviate(Iterable<String> values) {
    final list = values.toList();
    return list.length <= 8
        ? list.join(', ')
        : '${list.take(8).join(', ')}, … (${list.length})';
  }

  final fc = request.functionCode.label;
  return switch (request) {
    WriteSingleRegisterRequest(:final address, :final value) =>
      '$fc · ${holding(address)} = ${register(value)}',
    WriteSingleCoilRequest(:final address, :final value) =>
      '$fc · ${coil(address)} = ${value ? 'ON' : 'OFF'}',
    WriteMultipleRegistersRequest(:final address, :final values) =>
      '$fc · ${range(holding, address, values.length)} = '
          '${abbreviate(values.map(formatHex))}',
    WriteMultipleCoilsRequest(:final address, :final values) =>
      '$fc · ${range(coil, address, values.length)} = '
          '${abbreviate(values.map((v) => v ? '1' : '0'))}',
    MaskWriteRegisterRequest(:final address, :final andMask, :final orMask) =>
      '$fc · ${holding(address)} AND ${formatHex(andMask)} '
          'OR ${formatHex(orMask)}',
    ReadWriteMultipleRegistersRequest(
      :final writeAddress,
      :final writeValues,
    ) =>
      '$fc · ${range(holding, writeAddress, writeValues.length)} = '
          '${abbreviate(writeValues.map(formatHex))}',
    _ => fc,
  };
}
