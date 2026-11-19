import 'dart:typed_data';

/// Big-endian PDU writer.
final class PduWriter {
  final _builder = BytesBuilder(copy: false);

  void u8(int value) => _builder.addByte(value & 0xFF);

  void u16(int value) {
    _builder
      ..addByte((value >> 8) & 0xFF)
      ..addByte(value & 0xFF);
  }

  void bytes(List<int> values) => _builder.add(values);

  void registers(List<int> values) => values.forEach(u16);

  Uint8List take() => _builder.takeBytes();
}

/// Thrown by [PduReader] when the data ends early or has extra bytes.
final class PduFormatException implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

final class PduReader {
  new(this._data, [this._position = 0]);

  final List<int> _data;
  int _position;

  int get position => _position;
  int get remaining => _data.length - _position;

  int u8() {
    _need(1);
    return _data[_position++];
  }

  int u16() {
    _need(2);
    final value = (_data[_position] << 8) | _data[_position + 1];
    _position += 2;
    return value;
  }

  Uint8List bytes(int count) {
    _need(count);
    final result = Uint8List.fromList(
      _data.sublist(_position, _position + count),
    );
    _position += count;
    return result;
  }

  List<int> registers(int count) => [for (var i = 0; i < count; i++) u16()];

  void expectEnd() {
    if (remaining != 0) {
      throw PduFormatException('$remaining unexpected trailing byte(s)');
    }
  }

  void _need(int count) {
    if (remaining < count) {
      throw PduFormatException(
        'PDU too short: need $count more byte(s) at offset $_position',
      );
    }
  }
}

/// Coil/discrete bits: LSB of the first byte is the first address.
Uint8List packBits(List<bool> bits) {
  final bytes = Uint8List((bits.length + 7) >> 3);
  for (var i = 0; i < bits.length; i++) {
    if (bits[i]) bytes[i >> 3] |= 1 << (i & 7);
  }
  return bytes;
}

List<bool> unpackBits(List<int> bytes, int count) => [
  for (var i = 0; i < count; i++) (bytes[i >> 3] >> (i & 7)) & 1 == 1,
];
