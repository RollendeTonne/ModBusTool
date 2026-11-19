import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_transaction.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';

@immutable
final class FunctionStatistics {
  const new({this.requests = 0, this.errors = 0});

  final int requests;
  final int errors;
}

/// Running aggregates over all transactions since [since]. Independent of
/// the (bounded) log so counts stay exact in long sessions.
@immutable
final class CommunicationStatistics {
  const new({
    required this.since,
    this.requests = 0,
    this.successes = 0,
    this.deviceExceptions = 0,
    this.timeouts = 0,
    this.protocolErrors = 0,
    this.connectionErrors = 0,
    this.retries = 0,
    this.latencyCount = 0,
    this.latencyTotal = Duration.zero,
    this.latencyMin,
    this.latencyMax,
    this.byFunction = const {},
  });

  final DateTime since;
  final int requests;
  final int successes;
  final int deviceExceptions;
  final int timeouts;
  final int protocolErrors;
  final int connectionErrors;

  /// Extra attempts beyond the first.
  final int retries;
  final int latencyCount;
  final Duration latencyTotal;
  final Duration? latencyMin;
  final Duration? latencyMax;

  /// Keyed by function code label, e.g. `FC03`.
  final Map<String, FunctionStatistics> byFunction;

  int get errors => requests - successes;

  double get errorRate => requests == 0 ? 0 : errors / requests;

  Duration? get latencyAverage =>
      latencyCount == 0 ? null : latencyTotal ~/ latencyCount;

  CommunicationStatistics add(ModbusTransaction t) {
    final error = t.error;
    final latency = t.latency;
    final label = t.request.functionCode.label;
    final fc = byFunction[label] ?? const FunctionStatistics();
    return CommunicationStatistics(
      since: since,
      requests: requests + 1,
      successes: successes + (error == null ? 1 : 0),
      deviceExceptions:
          deviceExceptions + (error is ModbusDeviceException ? 1 : 0),
      timeouts: timeouts + (error is ModbusTimeoutException ? 1 : 0),
      protocolErrors:
          protocolErrors + (error is ModbusProtocolException ? 1 : 0),
      connectionErrors:
          connectionErrors + (error is ModbusConnectionException ? 1 : 0),
      retries: retries + (t.attempts > 1 ? t.attempts - 1 : 0),
      latencyCount: latencyCount + (latency == null ? 0 : 1),
      latencyTotal: latencyTotal + (latency ?? Duration.zero),
      latencyMin: latency == null
          ? latencyMin
          : (latencyMin == null || latency < latencyMin!
                ? latency
                : latencyMin),
      latencyMax: latency == null
          ? latencyMax
          : (latencyMax == null || latency > latencyMax!
                ? latency
                : latencyMax),
      byFunction: {
        ...byFunction,
        label: FunctionStatistics(
          requests: fc.requests + 1,
          errors: fc.errors + (error == null ? 0 : 1),
        ),
      },
    );
  }
}
