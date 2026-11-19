import 'dart:typed_data';

/// CRC-16/MODBUS (reflected poly 0xA001, init 0xFFFF), table-driven.
final Uint16List _table = () {
  final table = Uint16List(256);
  for (var i = 0; i < 256; i++) {
    var crc = i;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xA001 : crc >> 1;
    }
    table[i] = crc;
  }
  return table;
}();

int crc16Modbus(List<int> bytes, [int start = 0, int? end]) {
  final stop = end ?? bytes.length;
  var crc = 0xFFFF;
  for (var i = start; i < stop; i++) {
    crc = (crc >> 8) ^ _table[(crc ^ bytes[i]) & 0xFF];
  }
  return crc;
}

/// RTU frames carry the CRC low byte first.
Uint8List appendCrc(List<int> body) {
  final crc = crc16Modbus(body);
  return Uint8List.fromList([...body, crc & 0xFF, crc >> 8]);
}

/// True if the last two bytes are the CRC of everything before them.
bool hasValidCrc(List<int> frame) {
  if (frame.length < 3) return false;
  final n = frame.length;
  return crc16Modbus(frame, 0, n - 2) == (frame[n - 2] | (frame[n - 1] << 8));
}
