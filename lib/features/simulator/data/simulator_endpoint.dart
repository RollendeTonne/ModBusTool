import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:modbus_explorer/features/modbus/data/channel/byte_channel.dart';
import 'package:modbus_explorer/features/modbus/data/codec/framing.dart';
import 'package:modbus_explorer/features/modbus/data/codec/pdu_codec.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_limits.dart';
import 'package:modbus_explorer/features/simulator/data/request_handler.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_bank.dart';

/// Fault injection, both random (demo) and deterministic (tests).
final class SimulatorFaults {
  new({
    this.latency = Duration.zero,
    this.dropProbability = 0,
    this.corruptProbability = 0,
    Random? random,
  }) : _random = random ?? Random();

  Duration latency;
  double dropProbability;
  double corruptProbability;

  /// Next N responses are dropped / corrupted regardless of probabilities.
  int dropNext = 0;
  int corruptNext = 0;

  final Random _random;

  bool _shouldDrop() {
    if (dropNext > 0) {
      dropNext--;
      return true;
    }
    return dropProbability > 0 && _random.nextDouble() < dropProbability;
  }

  bool _shouldCorrupt() {
    if (corruptNext > 0) {
      corruptNext--;
      return true;
    }
    return corruptProbability > 0 && _random.nextDouble() < corruptProbability;
  }
}

/// Server side of a simulated connection: decodes request frames, lets the
/// addressed device answer and writes the response frame.
final class SimulatorEndpoint {
  new({
    required ByteChannel channel,
    required ModbusFraming framing,
    required this._bank,
    SimulatorFaults? faults,
  }) : _channel = channel,
       _framing = framing,
       faults = faults ?? SimulatorFaults(),
       _assembler = framing.newAssembler(expectRequests: true) {
    _subscription = channel.input.listen(_onBytes);
  }

  final ByteChannel _channel;
  final ModbusFraming _framing;
  final SimulatorBank _bank;
  final FrameAssembler _assembler;
  final SimulatorFaults faults;
  late final StreamSubscription<Uint8List> _subscription;

  /// Unit IDs that address "this device" on TCP regardless of the bank.
  static const _tcpWildcardUnits = {0, 0xFF};

  void _onBytes(Uint8List bytes) {
    for (final event in _assembler.addBytes(bytes)) {
      // Like real devices: silently ignore frames with bad CRC or framing.
      if (event is DecodedFrame) unawaited(_handle(event));
    }
  }

  Future<void> _handle(DecodedFrame frame) async {
    final isRtuBroadcast =
        _framing.kind == FrameKind.rtu &&
        frame.unitId == ModbusLimits.broadcastUnitId;
    if (isRtuBroadcast) {
      _applyBroadcast(frame.pdu);
      return;
    }
    final device =
        _bank.devices[frame.unitId] ??
        (_framing.kind == FrameKind.tcp &&
                _tcpWildcardUnits.contains(frame.unitId)
            ? _bank.devices.values.firstOrNull
            : null);
    // Unknown unit: no answer, exactly like an absent RTU slave.
    if (device == null) return;

    final responsePdu = handleRequestPdu(device, frame.pdu);
    if (faults.latency > Duration.zero) {
      await Future<void>.delayed(faults.latency);
    }
    if (faults._shouldDrop()) return;
    final response = _framing.encodeFrame(
      unitId: frame.unitId,
      pdu: responsePdu,
      transactionId: frame.transactionId ?? 0,
    );
    if (faults._shouldCorrupt()) {
      // Flip bits in the last byte: breaks the CRC (RTU) or the data (TCP).
      response[response.length - 1] ^= 0x5A;
    }
    try {
      await _channel.write(response);
    } on Object {
      // Client went away while we were answering.
    }
  }

  void _applyBroadcast(Uint8List pdu) {
    try {
      final request = PduCodec.decodeRequest(pdu);
      if (!request.isWrite) return;
      for (final device in _bank.devices.values) {
        device.handle(request);
      }
    } on RequestRejected {
      // Broadcasts get no answer, not even an exception.
    }
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _channel.close();
  }
}
