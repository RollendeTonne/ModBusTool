import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';
import 'package:modbus_explorer/features/connection/presentation/profiles_controller.dart';
import 'package:modbus_explorer/features/modbus/data/client/modbus_client.dart';
import 'package:modbus_explorer/features/modbus/data/modbus_providers.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_errors.dart';

@immutable
sealed class ConnectionState {
  const new();

  ConnectionProfile? get profile => null;
}

final class Disconnected extends ConnectionState {
  const new();
}

final class Connecting extends ConnectionState {
  const new(this.profile, {this.attempt = 0, this.lastError});

  @override
  final ConnectionProfile profile;

  /// > 0 while auto-reconnecting.
  final int attempt;
  final Object? lastError;
}

final class Connected extends ConnectionState {
  const new(this.profile, this.client, this.since);

  @override
  final ConnectionProfile profile;
  final ModbusClient client;
  final DateTime since;
}

final class ConnectionFailed extends ConnectionState {
  const new(this.profile, this.error, this.at);

  @override
  final ConnectionProfile profile;
  final Object error;
  final DateTime at;
}

final class ConnectionController extends Notifier<ConnectionState> {
  /// Back-off for auto-reconnect; the last value repeats.
  static const reconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
  ];

  /// Incremented on every connect/disconnect so stale async results from
  /// an earlier attempt are ignored.
  int _generation = 0;
  Timer? _reconnectTimer;

  /// Mirrors the client in [state]; `state` is not readable in onDispose.
  ModbusClient? _client;

  @override
  ConnectionState build() {
    ref.onDispose(() {
      // Invalidate pending callbacks before closing the client, whose
      // `done` would otherwise report a "lost" connection.
      _generation++;
      _reconnectTimer?.cancel();
      final client = _client;
      if (client != null) unawaited(client.close());
    });
    return const Disconnected();
  }

  Future<void> connect(ConnectionProfile profile) async {
    await disconnect();
    final generation = _generation;
    await _open(profile, generation, attempt: 0);
  }

  Future<void> disconnect() async {
    _generation++;
    _reconnectTimer?.cancel();
    final client = _client;
    _client = null;
    state = const Disconnected();
    await client?.close();
  }

  Future<void> _open(
    ConnectionProfile profile,
    int generation, {
    required int attempt,
    Object? lastError,
  }) async {
    state = Connecting(profile, attempt: attempt, lastError: lastError);
    final ModbusClient client;
    try {
      client = await ref.read(connectionFactoryProvider).open(profile.config);
    } on Object catch (e) {
      if (!ref.mounted || generation != _generation) return;
      if (attempt > 0 && profile.autoReconnect) {
        _scheduleReconnect(profile, generation, attempt + 1, e);
      } else {
        state = ConnectionFailed(profile, e, DateTime.now());
      }
      return;
    }
    if (!ref.mounted || generation != _generation) {
      await client.close();
      return;
    }
    _client = client;
    state = Connected(profile, client, DateTime.now());
    unawaited(
      ref.read(profilesControllerProvider.notifier).markUsed(profile.id),
    );
    unawaited(
      client.done.then((_) => _onConnectionLost(profile, client, generation)),
    );
  }

  void _onConnectionLost(
    ConnectionProfile profile,
    ModbusClient client,
    int generation,
  ) {
    // Ignore our own disconnect(), disposal and replaced connections.
    if (!ref.mounted || generation != _generation) return;
    if (_client != client) return;
    _client = null;
    const error = ModbusConnectionException(
      'Connection lost',
      kind: ConnectionErrorKind.closed,
    );
    if (profile.autoReconnect) {
      _scheduleReconnect(profile, generation, 1, error);
    } else {
      state = ConnectionFailed(profile, error, DateTime.now());
    }
  }

  void _scheduleReconnect(
    ConnectionProfile profile,
    int generation,
    int attempt,
    Object lastError,
  ) {
    state = Connecting(profile, attempt: attempt, lastError: lastError);
    final delay =
        reconnectDelays[(attempt - 1).clamp(0, reconnectDelays.length - 1)];
    _reconnectTimer = Timer(delay, () {
      if (!ref.mounted || generation != _generation) return;
      unawaited(
        _open(profile, generation, attempt: attempt, lastError: lastError),
      );
    });
  }
}

final connectionControllerProvider =
    NotifierProvider<ConnectionController, ConnectionState>(
      ConnectionController.new,
    );

final activeClientProvider = Provider<ModbusClient?>(
  (ref) => switch (ref.watch(connectionControllerProvider)) {
    Connected(:final client) => client,
    _ => null,
  },
);
