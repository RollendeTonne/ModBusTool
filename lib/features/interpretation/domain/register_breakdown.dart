import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';

/// All views of a single 16-bit register that need no byte-order choice
/// beyond high/low byte.
@immutable
final class RegisterBreakdown {
  factory(int raw) {
    RangeError.checkValueInInterval(raw, 0, 0xFFFF, 'raw');
    return RegisterBreakdown._(raw);
  }

  const new _(this.raw);

  final int raw;

  int get unsigned => raw;
  int get signed => raw.toSigned(16);
  int get highByte => raw >> 8;
  int get lowByte => raw & 0xFF;
  int get highByteSigned => highByte.toSigned(8);
  int get lowByteSigned => lowByte.toSigned(8);

  String get hex => formatHex(raw);
  String get binary => formatBinary(raw);

  /// `bits[0]` is the least significant bit (bit 0 in device manuals).
  List<bool> get bits => [for (var i = 0; i < 16; i++) (raw >> i) & 1 == 1];

  bool bit(int index) {
    RangeError.checkValueInInterval(index, 0, 15, 'index');
    return (raw >> index) & 1 == 1;
  }

  /// Returns the register with [index] set to [value].
  int withBit(int index, {required bool value}) {
    RangeError.checkValueInInterval(index, 0, 15, 'index');
    return value ? raw | (1 << index) : raw & ~(1 << index) & 0xFFFF;
  }

  /// Both bytes as characters (AB order); non-printable as `·`.
  String get ascii => String.fromCharCodes([highByte, lowByte].map(_printable));

  static int _printable(int byte) => byte >= 0x20 && byte < 0x7F
      ? byte
      : ValueFormatter.nonPrintableReplacement.codeUnitAt(0);
}
