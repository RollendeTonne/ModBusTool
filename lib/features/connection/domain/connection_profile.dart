import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/connection/domain/connection_config.dart';
import 'package:modbus_explorer/features/connection/domain/serial_settings.dart';

enum ConnectionKind { tcp, rtu, rtuOverTcp, simulator }

extension ConnectionConfigKind on ConnectionConfig {
  ConnectionKind get kind => switch (this) {
    TcpConnectionConfig() => ConnectionKind.tcp,
    RtuConnectionConfig() => ConnectionKind.rtu,
    RtuOverTcpConnectionConfig() => ConnectionKind.rtuOverTcp,
    SimulatorConnectionConfig() => ConnectionKind.simulator,
  };

  /// One-line technical summary, e.g. `192.168.0.10:502 · ID 1`.
  String get summary {
    final endpoint = switch (this) {
      TcpConnectionConfig(:final host, :final port) ||
      RtuOverTcpConnectionConfig(:final host, :final port) => '$host:$port',
      RtuConnectionConfig(:final serial) =>
        '${serial.portName} ${serial.shortDescription}',
      SimulatorConnectionConfig(:final framing) =>
        framing == SimulatorFraming.tcp ? 'MBAP' : 'RTU',
    };
    return '$endpoint · ID ${options.unitId}';
  }
}

@immutable
final class ConnectionProfile {
  const new({
    required this.id,
    required this.name,
    required this.config,
    required this.createdAt,
    this.lastUsedAt,
    this.autoReconnect = false,
  });

  final String id;
  final String name;
  final ConnectionConfig config;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  /// Reconnect with back-off when an open connection drops.
  final bool autoReconnect;

  ConnectionProfile copyWith({
    String? id,
    String? name,
    ConnectionConfig? config,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? autoReconnect,
  }) => ConnectionProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    config: config ?? this.config,
    createdAt: createdAt ?? this.createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    autoReconnect: autoReconnect ?? this.autoReconnect,
  );

  @override
  bool operator ==(Object other) =>
      other is ConnectionProfile &&
      other.id == id &&
      other.name == name &&
      other.config == config &&
      other.createdAt == createdAt &&
      other.lastUsedAt == lastUsedAt &&
      other.autoReconnect == autoReconnect;

  @override
  int get hashCode =>
      Object.hash(id, name, config, createdAt, lastUsedAt, autoReconnect);
}

/// Defaults used when the user picks a connection type in the editor.
ConnectionConfig defaultConfigFor(
  ConnectionKind kind, {
  RequestOptions options = const RequestOptions(),
  String? serialPort,
}) => switch (kind) {
  ConnectionKind.tcp => TcpConnectionConfig(host: '', options: options),
  ConnectionKind.rtuOverTcp => RtuOverTcpConnectionConfig(
    host: '',
    options: options,
  ),
  ConnectionKind.rtu => RtuConnectionConfig(
    serial: SerialSettings(portName: serialPort ?? ''),
    options: options,
  ),
  ConnectionKind.simulator => SimulatorConnectionConfig(options: options),
};
