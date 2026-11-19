// Live test against a real MQTT broker – not part of `flutter test`.
//
//   tool/mqtt/generate_certs.sh && docker compose up -d
//   MQTT_HOST=localhost flutter test test_live/mqtt_live_test.dart
//
// Expects the listeners of docker-compose.yml (1883 anonymous, 1884 with
// demo/demo-pass, 8883 TLS with docker/mosquitto/certs/ca.crt, 9001 WS).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt311_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt5_session.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_session.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';

final String? host = Platform.environment['MQTT_HOST'];

MqttSession session(MqttConnectionConfig config, [MqttSecrets? secrets]) =>
    config.protocolVersion == MqttProtocolVersion.v5
    ? Mqtt5Session(config, secrets ?? const MqttSecrets())
    : Mqtt311Session(config, secrets ?? const MqttSecrets());

Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// Subscribes, publishes and returns the echoed message.
Future<MqttMessageRecord> roundTrip(
  MqttSession s,
  MqttOutgoingMessage message,
) async {
  final received = s.messages.firstWhere((m) => m.topic == message.topic);
  s.subscribe(
    MqttSubscriptionSpec(filter: message.topic, qos: MqttQosLevel.atLeastOnce),
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));
  s.publish(message);
  return await received.timeout(const Duration(seconds: 5));
}

void main() {
  final skip = host == null ? 'MQTT_HOST not set' : null;
  final topic = 'pe-live/${DateTime.now().microsecondsSinceEpoch}';
  final caPem = File('docker/mosquitto/certs/ca.crt').existsSync()
      ? File('docker/mosquitto/certs/ca.crt').readAsStringSync()
      : null;

  for (final version in MqttProtocolVersion.values) {
    group('MQTT ${version.name}', () {
      test('TCP round trip with QoS 1', () async {
        final s = session(
          MqttConnectionConfig(host: host!, protocolVersion: version),
        );
        await s.connect();
        final echo = await roundTrip(
          s,
          MqttOutgoingMessage(
            topic: '$topic/${version.name}/tcp',
            payload: bytes('hello'),
            qos: MqttQosLevel.atLeastOnce,
          ),
        );
        expect(utf8.decode(echo.payload), 'hello');
        expect(echo.qos, MqttQosLevel.atLeastOnce);
        await s.disconnect();
      });

      test('demo publisher topics arrive (retained + binary)', () async {
        final s = session(
          MqttConnectionConfig(host: host!, protocolVersion: version),
        );
        await s.connect();
        final status = s.messages.firstWhere(
          (m) => m.topic == 'factory/hall1/status',
        );
        final counter = s.messages.firstWhere(
          (m) => m.topic == 'factory/hall1/meter/counter',
        );
        s.subscribe(const MqttSubscriptionSpec(filter: 'factory/#'));
        final retained = await status.timeout(const Duration(seconds: 5));
        expect(retained.retain, isTrue);
        expect(utf8.decode(retained.payload), 'online');
        final binary = await counter.timeout(const Duration(seconds: 5));
        expect(binary.payload, hasLength(4));
        await s.disconnect();
      });

      test('wrong password is refused with a CONNACK code', () async {
        final s = session(
          MqttConnectionConfig(
            host: host!,
            port: 1884,
            protocolVersion: version,
            username: 'demo',
            hasPassword: true,
          ),
          const MqttSecrets(password: 'wrong'),
        );
        try {
          await s.connect();
          fail('connected with a wrong password');
        } on MqttConnectFailure catch (f) {
          expect(f.kind, MqttFailureKind.refused);
          // Prints the broker's code for the docs (Mosquitto: 5 / 0x87).
          // ignore: avoid_print
          print('${version.name} refused with code ${f.code}');
        }
      });

      test('correct password connects', () async {
        final s = session(
          MqttConnectionConfig(
            host: host!,
            port: 1884,
            protocolVersion: version,
            username: 'demo',
            hasPassword: true,
          ),
          const MqttSecrets(password: 'demo-pass'),
        );
        await s.connect();
        await s.disconnect();
      });

      test(
        'TLS with own CA, rejected without it, accepted if allowed',
        () async {
          final base = MqttConnectionConfig(
            host: host!,
            port: 8883,
            transport: MqttTransport.tls,
            protocolVersion: version,
          );
          final withCa = session(
            base.copyWith(tls: MqttTlsSettings(caCertificatePem: caPem)),
          );
          await withCa.connect();
          final echo = await roundTrip(
            withCa,
            MqttOutgoingMessage(
              topic: '$topic/${version.name}/tls',
              payload: bytes('secure'),
            ),
          );
          expect(utf8.decode(echo.payload), 'secure');
          await withCa.disconnect();

          try {
            await session(base).connect();
            fail('self-signed certificate was accepted');
          } on MqttConnectFailure catch (f) {
            expect(f.kind, MqttFailureKind.tls);
          }

          final insecure = session(
            base.copyWith(
              tls: const MqttTlsSettings(acceptInvalidCertificates: true),
            ),
          );
          await insecure.connect();
          await insecure.disconnect();
        },
        skip: caPem == null ? 'run tool/mqtt/generate_certs.sh' : null,
      );

      test('WebSocket round trip', () async {
        final s = session(
          MqttConnectionConfig(
            host: host!,
            port: 9001,
            transport: MqttTransport.ws,
            protocolVersion: version,
          ),
        );
        await s.connect();
        final echo = await roundTrip(
          s,
          MqttOutgoingMessage(
            topic: '$topic/${version.name}/ws',
            payload: bytes('over ws'),
          ),
        );
        expect(utf8.decode(echo.payload), 'over ws');
        await s.disconnect();
      });

      test('unreachable port is a network error', () async {
        try {
          await session(
            MqttConnectionConfig(
              host: host!,
              port: 1999,
              protocolVersion: version,
              connectTimeout: const Duration(seconds: 2),
            ),
          ).connect();
          fail('connected to a closed port');
        } on MqttConnectFailure catch (f) {
          expect(
            f.kind,
            anyOf(MqttFailureKind.network, MqttFailureKind.timeout),
          );
        }
      });
    }, skip: skip);
  }

  test('MQTT 5 properties survive the round trip', () async {
    final s = session(
      MqttConnectionConfig(
        host: host!,
        protocolVersion: MqttProtocolVersion.v5,
      ),
    );
    await s.connect();
    final echo = await roundTrip(
      s,
      MqttOutgoingMessage(
        topic: '$topic/v5/props',
        payload: bytes('{"a":1}'),
        properties: MqttMessageProperties(
          contentType: 'application/json',
          responseTopic: '$topic/reply',
          correlationData: bytes('req-1'),
          messageExpiry: const Duration(minutes: 5),
          userProperties: const [('site', 'test'), ('line', '7')],
        ),
      ),
    );
    final p = echo.properties;
    expect(p.contentType, 'application/json');
    expect(p.responseTopic, '$topic/reply');
    expect(utf8.decode(p.correlationData!), 'req-1');
    expect(p.userProperties, containsAll([('site', 'test'), ('line', '7')]));
    expect(p.messageExpiry, isNotNull);
    await s.disconnect();
  }, skip: skip);

  test('retained message can be cleared with an empty payload', () async {
    final retainedTopic = '$topic/retained';
    final s = session(MqttConnectionConfig(host: host!));
    await s.connect();
    s.publish(
      MqttOutgoingMessage(
        topic: retainedTopic,
        payload: bytes('keep'),
        retain: true,
        qos: MqttQosLevel.atLeastOnce,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    s.publish(
      MqttOutgoingMessage(
        topic: retainedTopic,
        payload: Uint8List(0),
        retain: true,
        qos: MqttQosLevel.atLeastOnce,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await s.disconnect();

    final check = session(MqttConnectionConfig(host: host!));
    await check.connect();
    final received = <MqttMessageRecord>[];
    check.messages.listen(received.add);
    check.subscribe(MqttSubscriptionSpec(filter: retainedTopic));
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(received, isEmpty);
    await check.disconnect();
  }, skip: skip);
}
