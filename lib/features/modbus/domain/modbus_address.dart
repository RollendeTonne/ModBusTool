import 'package:modbus_explorer/features/modbus/domain/addressing_mode.dart';
import 'package:modbus_explorer/features/modbus/domain/register_table.dart';

/// Highest protocol address (16-bit field in the PDU).
const maxProtocolAddress = 0xFFFF;

final class AddressFormatException extends FormatException {
  const new(super.message, [super.source]);
}

/// Converts between protocol addresses (0-based, as sent on the wire) and
/// what the user sees/enters.
abstract final class ModbusAddress {
  /// Formats [protocolAddress] for display.
  ///
  /// One-based mode uses Modicon notation: 5 digits (`40001`) while the
  /// register number fits in 4 digits, otherwise 6 digits (`465536`).
  static String format(
    int protocolAddress,
    RegisterTable table,
    AddressingMode mode,
  ) {
    _checkProtocolAddress(protocolAddress);
    return switch (mode) {
      AddressingMode.zeroBased => '$protocolAddress',
      AddressingMode.oneBased => _modicon(protocolAddress + 1, table),
    };
  }

  /// Parses user input into a protocol address.
  ///
  /// Accepts decimal or `0x` hex. In one-based mode a 5- or 6-digit number
  /// starting with [table]'s prefix digit is read as Modicon notation
  /// (`40001` → 0 for holding registers); anything else as a plain 1-based
  /// register number (`1` → 0). Leading zeros matter for coils (`00001`).
  static int parse(String input, RegisterTable table, AddressingMode mode) {
    final text = input.trim();
    if (text.isEmpty) {
      throw AddressFormatException('Address is empty', input);
    }
    final isHex = text.toLowerCase().startsWith('0x');
    final number = isHex
        ? int.tryParse(text.substring(2), radix: 16)
        : int.tryParse(text);
    if (number == null || number < 0) {
      throw AddressFormatException('Not a valid address', input);
    }

    final int protocolAddress;
    switch (mode) {
      case AddressingMode.zeroBased:
        protocolAddress = number;
      case AddressingMode.oneBased:
        final registerNumber = !isHex && _isModiconNotation(text, table)
            ? int.parse(text.substring(1))
            : number;
        if (registerNumber < 1) {
          throw AddressFormatException('One-based addresses start at 1', input);
        }
        protocolAddress = registerNumber - 1;
    }
    if (protocolAddress > maxProtocolAddress) {
      throw AddressFormatException('Address exceeds 65535', input);
    }
    return protocolAddress;
  }

  /// Throws if [count] items starting at [start] leave the address space.
  static void checkRange(int start, int count) {
    _checkProtocolAddress(start);
    if (count < 1) {
      throw RangeError.value(count, 'count', 'must be at least 1');
    }
    if (start + count - 1 > maxProtocolAddress) {
      throw RangeError(
        'Range $start..${start + count - 1} exceeds address 65535',
      );
    }
  }

  static bool _isModiconNotation(String text, RegisterTable table) =>
      (text.length == 5 || text.length == 6) &&
      text.codeUnitAt(0) - 0x30 == table.modiconPrefix;

  static String _modicon(int registerNumber, RegisterTable table) {
    final width = registerNumber <= 9999 ? 4 : 5;
    return '${table.modiconPrefix}'
        '${registerNumber.toString().padLeft(width, '0')}';
  }

  static void _checkProtocolAddress(int address) =>
      RangeError.checkValueInInterval(
        address,
        0,
        maxProtocolAddress,
        'protocolAddress',
      );
}
