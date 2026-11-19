/// Parses one register value as typed by the user: decimal (negative
/// values as 16-bit two's complement), `0x…` hex or `0b…` binary.
/// Returns `null` if invalid or outside 16 bit.
int? parseRegisterValue(String input) {
  final text = input.trim().toLowerCase().replaceAll('_', '');
  if (text.isEmpty) return null;
  final int? value;
  if (text.startsWith('0x')) {
    value = int.tryParse(text.substring(2), radix: 16);
  } else if (text.startsWith('0b')) {
    value = int.tryParse(text.substring(2), radix: 2);
  } else {
    value = int.tryParse(text);
  }
  if (value == null || value < -0x8000 || value > 0xFFFF) return null;
  return value & 0xFFFF;
}

final _separators = RegExp(r'[\s,;]+');

/// Comma/space separated register values; `null` if any entry is invalid.
List<int>? parseRegisterList(String input) {
  final parts = input.trim().split(_separators).where((p) => p.isNotEmpty);
  final values = <int>[];
  for (final part in parts) {
    final value = parseRegisterValue(part);
    if (value == null) return null;
    values.add(value);
  }
  return values.isEmpty ? null : values;
}

const _trueWords = {'1', 'on', 'true', 'ein', 'an'};
const _falseWords = {'0', 'off', 'false', 'aus'};

/// Comma/space separated coil states; `null` if any entry is invalid.
List<bool>? parseCoilList(String input) {
  final parts = input
      .trim()
      .toLowerCase()
      .split(_separators)
      .where((p) => p.isNotEmpty);
  final values = <bool>[];
  for (final part in parts) {
    if (_trueWords.contains(part)) {
      values.add(true);
    } else if (_falseWords.contains(part)) {
      values.add(false);
    } else {
      return null;
    }
  }
  return values.isEmpty ? null : values;
}
