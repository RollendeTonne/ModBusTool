import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service_android.dart';
import 'package:modbus_explorer/features/modbus/data/channel/serial_port_service_desktop.dart';
import 'package:modbus_explorer/features/modbus/data/client/connection_factory.dart';
import 'package:modbus_explorer/features/simulator/data/simulator_bank.dart';

final serialPortServiceProvider = Provider<SerialPortService>((ref) {
  final caps = ref.watch(platformCapabilitiesProvider);
  if (!caps.supportsSerial) return const UnsupportedSerialPortService();
  return defaultTargetPlatform == TargetPlatform.android
      ? const AndroidSerialPortService()
      : const DesktopSerialPortService();
});

/// One simulated device bank per app session, animated while in use.
final simulatorBankProvider = Provider<SimulatorBank>((ref) {
  final bank = SimulatorBank.demo()..startAnimation();
  ref.onDispose(bank.dispose);
  return bank;
});

final connectionFactoryProvider = Provider<ModbusConnectionFactory>(
  (ref) => ModbusConnectionFactory(
    serialPorts: ref.watch(serialPortServiceProvider),
    simulatorBank: () => ref.read(simulatorBankProvider),
  ),
);
