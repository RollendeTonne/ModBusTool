import 'dart:typed_data';

import 'package:modbus_explorer/modules/modbus/protocol/data/codec/pdu_codec.dart';
import 'package:modbus_explorer/modules/modbus/simulator/domain/simulated_device.dart';

/// Answers a raw request PDU like a real device would.
Uint8List handleRequestPdu(SimulatedDevice device, List<int> pdu) {
  try {
    final request = PduCodec.decodeRequest(pdu);
    return PduCodec.encodeResponse(request, device.handle(request));
  } on RequestRejected catch (e) {
    return PduCodec.encodeException(pdu.isEmpty ? 0 : pdu[0], e.code.code);
  }
}
