// fakeAsync tests drive futures with elapse()/flushMicrotasks() instead of
// awaiting them.
// ignore_for_file: discarded_futures

import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/mqtt/data/simulated_broker.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_errors.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';

Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  late SimulatedBroker broker;

  setUp(() => broker = SimulatedBroker());
  tearDown(() => broker.dispose());

  Future<(SimulatedMqttSession, List<MqttMessageRecord>)> client({
    MqttProtocolVersion version = MqttProtocolVersion.v5,
    String username = '',
  }) async {
    final session = SimulatedMqttSession(
      broker,
      MqttConnectionConfig(
        host: 'sim',
        simulated: true,
        protocolVersion: version,
        username: username,
      ),
    );
    final received = <MqttMessageRecord>[];
    session.messages.listen(received.add);
    await session.connect();
    return (session, received);
  }

  test(
    'retained messages are replayed on subscribe, with retain flag',
    () async {
      final (session, received) = await client();
      session.subscribe(const MqttSubscriptionSpec(filter: 'demo/#'));
      await pumpEventQueue();
      final status = received.singleWhere(
        (m) => m.topic == 'demo/plant/status',
      );
      expect(utf8.decode(status.payload), 'running');
      expect(status.retain, isTrue);
      await session.disconnect();
    },
  );

  test(r'# does not match $SYS, $SYS/# does', () async {
    final (session, received) = await client();
    session.subscribe(const MqttSubscriptionSpec(filter: '#'));
    await pumpEventQueue();
    expect(received.where((m) => m.topic.startsWith(r'$SYS')), isEmpty);
    session.subscribe(const MqttSubscriptionSpec(filter: r'$SYS/#'));
    await pumpEventQueue();
    expect(
      received.where((m) => m.topic == r'$SYS/broker/version'),
      hasLength(1),
    );
    await session.disconnect();
  });

  test(
    'publish reaches other clients; noLocal suppresses the echo (v5)',
    () async {
      final (a, receivedA) = await client();
      final (b, receivedB) = await client();
      a.subscribe(const MqttSubscriptionSpec(filter: 'chat/+', noLocal: true));
      b.subscribe(
        const MqttSubscriptionSpec(
          filter: 'chat/+',
          qos: MqttQosLevel.exactlyOnce,
        ),
      );
      a.publish(
        MqttOutgoingMessage(
          topic: 'chat/x',
          payload: bytes('hi'),
          qos: MqttQosLevel.atLeastOnce,
        ),
      );
      await pumpEventQueue();
      expect(receivedA.where((m) => m.topic == 'chat/x'), isEmpty);
      final atB = receivedB.singleWhere((m) => m.topic == 'chat/x');
      // Granted QoS is capped by the published QoS.
      expect(atB.qos, MqttQosLevel.atLeastOnce);
      expect(atB.retain, isFalse);
      await a.disconnect();
      await b.disconnect();
    },
  );

  test('empty retained publish clears the retained message', () async {
    final (session, received) = await client();
    session
      ..publish(
        MqttOutgoingMessage(topic: 'x/y', payload: bytes('1'), retain: true),
      )
      ..publish(
        MqttOutgoingMessage(topic: 'x/y', payload: Uint8List(0), retain: true),
      )
      ..subscribe(const MqttSubscriptionSpec(filter: 'x/#'));
    await pumpEventQueue();
    expect(received, isEmpty);
    await session.disconnect();
  });

  test('retain handling: doNotSend and sendIfNew', () async {
    final (session, received) = await client();
    session.subscribe(
      const MqttSubscriptionSpec(
        filter: 'demo/plant/status',
        retainHandling: MqttRetainHandling.doNotSend,
      ),
    );
    await pumpEventQueue();
    expect(received, isEmpty);
    const ifNew = MqttSubscriptionSpec(
      filter: 'demo/plant/status',
      retainHandling: MqttRetainHandling.sendIfNewSubscription,
    );
    session.subscribe(ifNew); // already exists → no replay
    await pumpEventQueue();
    expect(received, isEmpty);
    await session.disconnect();
  });

  test('MQTT 3.1.1 clients get no properties', () async {
    final (session, received) = await client(version: MqttProtocolVersion.v311);
    session.subscribe(
      const MqttSubscriptionSpec(filter: 'demo/plant/line1/info'),
    );
    await pumpEventQueue();
    expect(received.single.properties.isEmpty, isTrue);
    await session.disconnect();
  });

  test('user "denied" is refused with the version-specific code', () async {
    for (final (version, code) in [
      (MqttProtocolVersion.v311, 4),
      (MqttProtocolVersion.v5, 0x86),
    ]) {
      final session = SimulatedMqttSession(
        broker,
        MqttConnectionConfig(
          host: 's',
          simulated: true,
          protocolVersion: version,
          username: 'denied',
        ),
      );
      await expectLater(
        session.connect(),
        throwsA(
          isA<MqttConnectFailure>()
              .having((f) => f.kind, 'kind', MqttFailureKind.refused)
              .having((f) => f.code, 'code', code),
        ),
      );
    }
  });

  test('demo publisher sends JSON, binary and properties every interval', () {
    fakeAsync((async) {
      final broker = SimulatedBroker();
      final session = SimulatedMqttSession(
        broker,
        const MqttConnectionConfig(
          host: 's',
          simulated: true,
          protocolVersion: MqttProtocolVersion.v5,
        ),
      );
      final received = <MqttMessageRecord>[];
      session.messages.listen(received.add);
      session.connect();
      async.flushMicrotasks();
      session.subscribe(
        const MqttSubscriptionSpec(filter: 'demo/plant/line1/+'),
      );
      async.elapse(const Duration(seconds: 3));
      final temps = received
          .where((m) => m.topic.endsWith('temperature'))
          .toList();
      expect(temps, hasLength(3));
      expect(
        jsonDecode(utf8.decode(temps.first.payload)),
        containsPair('unit', '°C'),
      );
      expect(temps.first.properties.contentType, 'application/json');
      expect(temps.first.properties.userProperties, contains(('site', 'demo')));
      final counters = received
          .where((m) => m.topic.endsWith('counter'))
          .toList();
      expect(counters.first.payload, hasLength(4));
      session.disconnect();
      async.flushMicrotasks();
      // The publisher stops with the last client.
      expect(async.pendingTimers, isEmpty);
      broker.dispose();
    });
  });
}
