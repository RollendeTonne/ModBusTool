import 'dart:typed_data';

import 'package:modbus_explorer/features/modbus/data/codec/framing.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_limits.dart';

const mbapHeaderLength = 7;

/// MBAP length field counts unit ID + PDU.
const int _maxMbapLength = ModbusLimits.maxPduLength + 1;

final class MbapFraming implements ModbusFraming {
  const new();

  @override
  FrameKind get kind => FrameKind.tcp;

  @override
  Uint8List encodeFrame({
    required int unitId,
    required List<int> pdu,
    int transactionId = 0,
  }) {
    final length = pdu.length + 1;
    return Uint8List.fromList([
      (transactionId >> 8) & 0xFF,
      transactionId & 0xFF,
      0, // protocol identifier: always 0 for Modbus
      0,
      length >> 8,
      length & 0xFF,
      unitId & 0xFF,
      ...pdu,
    ]);
  }

  @override
  FrameAssembler newAssembler({required bool expectRequests}) =>
      MbapFrameAssembler();
}

final class MbapFrameAssembler implements FrameAssembler {
  final _buffer = <int>[];

  @override
  bool get hasPendingBytes => _buffer.isNotEmpty;

  @override
  List<FramingEvent> addBytes(List<int> bytes) {
    _buffer.addAll(bytes);
    final events = <FramingEvent>[];
    while (_buffer.length >= mbapHeaderLength) {
      final protocolId = (_buffer[2] << 8) | _buffer[3];
      final length = (_buffer[4] << 8) | _buffer[5];
      if (protocolId != 0 || length < 2 || length > _maxMbapLength) {
        // TCP has no resync marker; drop everything buffered.
        events.add(
          FramingError(_take(_buffer.length), FramingErrorKind.invalidHeader),
        );
        break;
      }
      final total = 6 + length;
      if (_buffer.length < total) break;
      final raw = _take(total);
      events.add(
        DecodedFrame(
          raw: raw,
          transactionId: (raw[0] << 8) | raw[1],
          unitId: raw[6],
          pdu: Uint8List.sublistView(raw, mbapHeaderLength),
        ),
      );
    }
    return events;
  }

  @override
  List<FramingEvent> flush() {
    if (_buffer.isEmpty) return const [];
    return [
      FramingError(_take(_buffer.length), FramingErrorKind.incompleteFrame),
    ];
  }

  Uint8List _take(int count) {
    final raw = Uint8List.fromList(_buffer.sublist(0, count));
    _buffer.removeRange(0, count);
    return raw;
  }
}
