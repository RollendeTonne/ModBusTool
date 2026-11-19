import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/modbus/connection/domain/serial_settings.dart';

/// Options shared by every connection type.
@immutable
final class RequestOptions {
  const new({
    this.unitId = 1,
    this.timeout = const Duration(seconds: 1),
    this.retries = 1,
  });

  final int unitId;
  final Duration timeout;

  /// Additional attempts after the first one.
  final int retries;

  RequestOptions copyWith({int? unitId, Duration? timeout, int? retries}) =>
      RequestOptions(
        unitId: unitId ?? this.unitId,
        timeout: timeout ?? this.timeout,
        retries: retries ?? this.retries,
      );

  @override
  bool operator ==(Object other) =>
      other is RequestOptions &&
      other.unitId == unitId &&
      other.timeout == timeout &&
      other.retries == retries;

  @override
  int get hashCode => Object.hash(unitId, timeout, retries);
}

@immutable
sealed class ConnectionConfig {
  const new({this.options = const RequestOptions()});

  final RequestOptions options;
}

final class TcpConnectionConfig extends ConnectionConfig {
  const new({required this.host, this.port = defaultPort, super.options});

  static const defaultPort = 502;

  final String host;
  final int port;

  @override
  bool operator ==(Object other) =>
      other is TcpConnectionConfig &&
      other.host == host &&
      other.port == port &&
      other.options == options;

  @override
  int get hashCode => Object.hash(host, port, options);
}

/// RTU frames tunnelled through a TCP socket (serial device servers).
final class RtuOverTcpConnectionConfig extends ConnectionConfig {
  const new({required this.host, this.port = defaultPort, super.options});

  /// Common default of serial device servers (e.g. Moxa NPort).
  static const defaultPort = 4001;

  final String host;
  final int port;

  @override
  bool operator ==(Object other) =>
      other is RtuOverTcpConnectionConfig &&
      other.host == host &&
      other.port == port &&
      other.options == options;

  @override
  int get hashCode => Object.hash(host, port, options);
}

final class RtuConnectionConfig extends ConnectionConfig {
  const new({required this.serial, super.options});

  final SerialSettings serial;

  @override
  bool operator ==(Object other) =>
      other is RtuConnectionConfig &&
      other.serial == serial &&
      other.options == options;

  @override
  int get hashCode => Object.hash(serial, options);
}

enum SimulatorFraming { tcp, rtu }

/// Built-in demo device, works on every platform without network access.
final class SimulatorConnectionConfig extends ConnectionConfig {
  const new({
    this.framing = SimulatorFraming.tcp,
    this.latency = const Duration(milliseconds: 5),
    this.dropProbability = 0,
    this.corruptProbability = 0,
    super.options,
  });

  final SimulatorFraming framing;
  final Duration latency;
  final double dropProbability;
  final double corruptProbability;

  @override
  bool operator ==(Object other) =>
      other is SimulatorConnectionConfig &&
      other.framing == framing &&
      other.latency == latency &&
      other.dropProbability == dropProbability &&
      other.corruptProbability == corruptProbability &&
      other.options == options;

  @override
  int get hashCode => Object.hash(
    framing,
    latency,
    dropProbability,
    corruptProbability,
    options,
  );
}
