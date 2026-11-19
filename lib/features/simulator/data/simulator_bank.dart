import 'dart:async';

import 'package:modbus_explorer/features/simulator/domain/demo_devices.dart';
import 'package:modbus_explorer/features/simulator/domain/simulated_device.dart';

/// Simulated devices by unit ID, shared by all simulator connections so
/// written values survive reconnects.
final class SimulatorBank {
  new(this.devices);

  factory demo() => SimulatorBank({
    demoUnitId: buildDemoDevice(),
    meterUnitId: buildMeterDevice(),
  });

  final Map<int, SimulatedDevice> devices;
  Timer? _ticker;
  int _tick = 0;

  /// Starts updating the dynamic demo values once per [interval].
  void startAnimation({Duration interval = const Duration(seconds: 1)}) {
    _ticker ??= Timer.periodic(interval, (_) {
      _tick++;
      final device = devices[demoUnitId];
      if (device != null) updateDemoDevice(device, DateTime.now(), _tick);
    });
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
  }
}
