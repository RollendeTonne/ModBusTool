import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/features/connection/domain/connection_status.dart';

// Placeholder until M4 wires in the real connection controller.
final connectionStatusProvider = Provider<ConnectionStatus>(
  (ref) => ConnectionStatus.disconnected,
);
