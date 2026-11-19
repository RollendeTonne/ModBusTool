import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modbus_explorer/features/connection/domain/connection_status.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';

final connectionStatusProvider = Provider<ConnectionStatus>(
  (ref) => switch (ref.watch(connectionControllerProvider)) {
    Disconnected() => ConnectionStatus.disconnected,
    Connecting() => ConnectionStatus.connecting,
    Connected() => ConnectionStatus.connected,
    ConnectionFailed() => ConnectionStatus.error,
  },
);
