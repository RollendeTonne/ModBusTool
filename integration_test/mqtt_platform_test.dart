import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:modbus_explorer/core/storage/secret_store.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt311_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt5_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';

/// Native parts of the MQTT module inside the real app:
/// `flutter test integration_test/mqtt_platform_test.dart -d macos`
/// Android emulator (host machine = 10.0.2.2):
/// `… -d emulator-5554 --dart-define=MQTT_HOST=10.0.2.2`
/// The broker tests need `docker compose up -d` on the host.
const brokerHost = String.fromEnvironment(
  'MQTT_HOST',
  defaultValue: 'localhost',
);

/// Base64 of docker/mosquitto/certs/ca.crt for the TLS test (optional):
/// `--dart-define=MQTT_CA_B64=$(base64 -i docker/mosquitto/certs/ca.crt)`.
const caBase64 = String.fromEnvironment('MQTT_CA_B64');

/// Subscribes to [topic], publishes once and waits for the echo.
Future<String> echo(MqttSession session, String topic, String text) async {
  final received = session.messages.firstWhere((m) => m.topic == topic);
  session.subscribe(MqttSubscriptionSpec(filter: topic));
  await Future<void>.delayed(const Duration(milliseconds: 300));
  session.publish(
    MqttOutgoingMessage(
      topic: topic,
      payload: Uint8List.fromList(utf8.encode(text)),
    ),
  );
  final message = await received.timeout(const Duration(seconds: 5));
  return utf8.decode(message.payload);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('secret store round trip in the system keychain', (tester) async {
    final store = SecureSecretStore();
    const key = 'mqtt.integration-test.password';
    await store.write(key, r'pä$$wörd');
    expect(await store.read(key), r'pä$$wörd');
    await store.write(key, null);
    expect(await store.read(key), isNull);
  });

  testWidgets('MQTT over the app network stack (local broker)', (tester) async {
    final session = Mqtt311Session(
      const MqttConnectionConfig(host: brokerHost),
      const MqttSecrets(),
    );
    try {
      await session.connect();
    } on Object catch (e) {
      markTestSkipped('no local broker: $e');
      return;
    }
    const topic = 'pe-integration/app';
    final echo = session.messages.firstWhere((m) => m.topic == topic);
    session.subscribe(const MqttSubscriptionSpec(filter: topic));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    session.publish(
      MqttOutgoingMessage(
        topic: topic,
        payload: Uint8List.fromList(utf8.encode('from app')),
      ),
    );
    final message = await echo.timeout(const Duration(seconds: 5));
    expect(utf8.decode(message.payload), 'from app');
    await session.disconnect();
  });

  testWidgets('password from the keychain authenticates at the broker', (
    tester,
  ) async {
    final store = SecureSecretStore();
    const key = 'mqtt.integration-test.broker';
    await store.write(key, 'demo-pass');
    final session = Mqtt5Session(
      const MqttConnectionConfig(
        host: brokerHost,
        port: 1884,
        protocolVersion: MqttProtocolVersion.v5,
        username: 'demo',
        hasPassword: true,
      ),
      MqttSecrets(password: await store.read(key)),
    );
    try {
      await session.connect();
    } on MqttConnectFailure catch (e) {
      if (e.kind == MqttFailureKind.network) {
        markTestSkipped('no local broker: $e');
        return;
      }
      rethrow;
    } finally {
      await store.write(key, null);
    }
    await session.disconnect();
  });

  testWidgets('WebSocket transport (port 9001)', (tester) async {
    final session = Mqtt311Session(
      const MqttConnectionConfig(
        host: brokerHost,
        port: 9001,
        transport: MqttTransport.ws,
      ),
      const MqttSecrets(),
    );
    try {
      await session.connect();
    } on MqttConnectFailure catch (e) {
      if (e.kind == MqttFailureKind.network) {
        markTestSkipped('no local broker: $e');
        return;
      }
      rethrow;
    }
    expect(await echo(session, 'pe-integration/ws', 'via ws'), 'via ws');
    await session.disconnect();
  });

  testWidgets('TLS with own CA, rejected without (port 8883)', (tester) async {
    const base = MqttConnectionConfig(
      host: brokerHost,
      port: 8883,
      transport: MqttTransport.tls,
      protocolVersion: MqttProtocolVersion.v5,
    );
    final ca = utf8.decode(base64.decode(caBase64));
    final trusted = Mqtt5Session(
      base.copyWith(tls: MqttTlsSettings(caCertificatePem: ca)),
      const MqttSecrets(),
    );
    await trusted.connect();
    expect(await echo(trusted, 'pe-integration/tls', 'secure'), 'secure');
    await trusted.disconnect();

    final untrusted = Mqtt5Session(base, const MqttSecrets());
    await expectLater(
      untrusted.connect(),
      throwsA(
        isA<MqttConnectFailure>().having(
          (f) => f.kind,
          'kind',
          MqttFailureKind.tls,
        ),
      ),
    );
  }, skip: caBase64.isEmpty);
}
