// fakeAsync tests drive futures with elapse()/flushMicrotasks() instead of
// awaiting them.
// ignore_for_file: discarded_futures, cascade_invocations

import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/core/storage/secret_store.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_profile_repository.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_session_factory.dart';
import 'package:modbus_explorer/modules/mqtt/data/simulated_broker.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_log.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_message_log_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profiles_controller.dart';

import '../../helpers/container.dart';

MqttProfile simProfile({String username = '', bool autoReconnect = true}) =>
    MqttProfile(
      id: 'p1',
      name: 'Sim',
      createdAt: DateTime(2026),
      autoReconnect: autoReconnect,
      config: MqttConnectionConfig(
        host: 'sim',
        simulated: true,
        protocolVersion: MqttProtocolVersion.v5,
        username: username,
        subscriptions: const [MqttSubscriptionSpec(filter: 'test/#')],
      ),
    );

void main() {
  test('first start seeds the demo broker profile', () async {
    final container = createTestContainer();
    addTearDown(container.dispose);
    final profiles = await container.read(
      mqttProfilesControllerProvider.future,
    );
    expect(profiles.single.config.simulated, isTrue);
    expect(profiles.single.config.subscriptions.map((s) => s.filter), [
      'demo/#',
      r'$SYS/#',
    ]);
  });

  test('connect, publish round trip through the log, disconnect', () async {
    final container = createTestContainer();
    addTearDown(container.dispose);
    final profile = simProfile();
    await container.read(mqttProfilesControllerProvider.notifier).save(profile);
    final controller = container.read(
      mqttConnectionControllerProvider.notifier,
    );
    container.listen(mqttMessageLogControllerProvider, (_, _) {});

    await controller.connect(profile);
    final state = container.read(mqttConnectionControllerProvider);
    expect(state.status, MqttConnectionStatus.connected);
    expect(state.clientId, startsWith('pe-'));

    controller.publish(
      MqttOutgoingMessage(
        topic: 'test/a',
        payload: Uint8List.fromList(utf8.encode('42')),
      ),
    );
    await Future<void>.delayed(MqttMessageLogController.flushInterval * 2);
    final log = container.read(mqttMessageLogControllerProvider).messages;
    // Sent record + the broker's echo (own subscription, noLocal off).
    expect(log.map((m) => m.direction), [
      MqttDirection.sent,
      MqttDirection.received,
    ]);

    await controller.disconnect();
    expect(
      container.read(mqttConnectionControllerProvider).status,
      MqttConnectionStatus.disconnected,
    );
    expect(
      () => controller.publish(
        MqttOutgoingMessage(topic: 't', payload: Uint8List(0)),
      ),
      throwsStateError,
    );
  });

  test('refused connection is an error without retries', () async {
    final container = createTestContainer();
    addTearDown(container.dispose);
    await container
        .read(mqttConnectionControllerProvider.notifier)
        .connect(simProfile(username: 'denied'));
    final state = container.read(mqttConnectionControllerProvider);
    expect(state.status, MqttConnectionStatus.error);
    expect(state.failure!.kind, MqttFailureKind.refused);
    expect(state.failure!.code, 0x86);
  });

  test('a refused connection is logged as an error event', () async {
    final container = createTestContainer();
    addTearDown(container.dispose);
    container.listen(mqttMessageLogControllerProvider, (_, _) {});
    await container
        .read(mqttConnectionControllerProvider.notifier)
        .connect(simProfile(username: 'denied'));
    await Future<void>.delayed(MqttMessageLogController.flushInterval * 2);
    final entries = container.read(mqttMessageLogControllerProvider).entries;
    final errors = entries.where(
      const MonitorFilter(onlyErrors: true).matcher(),
    );
    expect(errors.single, isA<MqttLogEvent>());
    expect((errors.single as MqttLogEvent).kind, MqttEventKind.connectFailed);
    expect((errors.single as MqttLogEvent).detail, contains('code 134'));
  });

  test('password comes from the secret store', () async {
    MqttSecrets? used;
    final secrets = InMemorySecretStore({
      MqttProfileRepository.passwordKey('p1'): 's3cret',
    });
    final container = createTestContainer(
      secrets: secrets,
      overrides: [
        mqttSessionFactoryProvider.overrideWith((ref) {
          final broker = ref.watch(simulatedBrokerProvider);
          return (config, s) {
            used = s;
            return SimulatedMqttSession(broker, config);
          };
        }),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(mqttConnectionControllerProvider.notifier)
        .connect(simProfile());
    expect(used!.password, 's3cret');
  });

  test('subscription changes apply live and persist in the profile', () async {
    final container = createTestContainer();
    addTearDown(container.dispose);
    final profile = simProfile();
    final profiles = container.read(mqttProfilesControllerProvider.notifier);
    await container.read(mqttProfilesControllerProvider.future);
    await profiles.save(profile);
    final controller = container.read(
      mqttConnectionControllerProvider.notifier,
    );
    await controller.connect(profile);

    await controller.putSubscription(
      const MqttSubscriptionSpec(filter: 'demo/plant/status'),
    );
    await controller.putSubscription(
      const MqttSubscriptionSpec(filter: 'test/#', enabled: false),
    );
    await controller.removeSubscription('demo/plant/status');
    final stored = profiles.byId('p1')!;
    expect(stored.config.subscriptions.single.filter, 'test/#');
    expect(stored.config.subscriptions.single.enabled, isFalse);
    expect(
      container
          .read(mqttConnectionControllerProvider)
          .profile!
          .config
          .subscriptions,
      stored.config.subscriptions,
    );
  });

  test('connection loss reconnects with back-off and resubscribes', () {
    fakeAsync((async) {
      final container = createTestContainer();
      final controller = container.read(
        mqttConnectionControllerProvider.notifier,
      );
      controller.connect(simProfile());
      async.flushMicrotasks();
      final first = controller.session! as SimulatedMqttSession;
      first.simulateConnectionLoss();
      async.flushMicrotasks();
      var state = container.read(mqttConnectionControllerProvider);
      expect(state.status, MqttConnectionStatus.reconnecting);
      expect(state.reconnectAttempt, 1);
      expect(state.failure!.kind, MqttFailureKind.connectionLost);

      async.elapse(const Duration(seconds: 1));
      state = container.read(mqttConnectionControllerProvider);
      expect(state.status, MqttConnectionStatus.connected);
      expect(controller.session, isNot(same(first)));

      controller.disconnect();
      async.flushMicrotasks();
      container.dispose();
    });
  });

  test('without auto-reconnect a loss ends in the error state', () {
    fakeAsync((async) {
      final container = createTestContainer();
      final controller = container.read(
        mqttConnectionControllerProvider.notifier,
      );
      controller.connect(simProfile(autoReconnect: false));
      async.flushMicrotasks();
      (controller.session! as SimulatedMqttSession).simulateConnectionLoss();
      async.flushMicrotasks();
      expect(
        container.read(mqttConnectionControllerProvider).status,
        MqttConnectionStatus.error,
      );
      container.dispose();
    });
  });

  test('back-off doubles up to 30 s', () {
    expect(
      [
        for (var i = 1; i <= 7; i++)
          MqttConnectionController.backoffFor(i).inSeconds,
      ],
      [1, 2, 4, 8, 16, 30, 30],
    );
  });
}
