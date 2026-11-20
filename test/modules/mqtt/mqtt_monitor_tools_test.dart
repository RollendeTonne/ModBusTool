import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_log.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_message_log_controller.dart';

import '../../helpers/fake_files.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeFileExchange files;

  setUp(() => files = FakeFileExchange());

  Future<void> openMqtt(
    WidgetTester tester, {
    Size size = const Size(1400, 900),
  }) async {
    await tester.pumpModbusApp(
      size: size,
      reduceMotion: true,
      overrides: [fileExchangeProvider.overrideWithValue(files)],
    );
    await tester.tap(find.byKey(const Key('module.mqtt')));
    await tester.pumpAndSettle();
  }

  Future<void> connectDemo(WidgetTester tester) async {
    await tester.tap(find.text('Demo-Broker (Simulator)'));
    await tester.pumpAndSettle();
  }

  Future<void> disconnect(WidgetTester tester) async {
    await tester.tapNavigation('Connection');
    await tester.tap(find.byKey(const Key('mqtt.disconnect')));
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  testWidgets('monitor: events, filters, details, export, buffer size', (
    tester,
  ) async {
    await openMqtt(tester);
    await connectDemo(tester);
    await tester.tapNavigation('Monitor');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Connection events are logged alongside the messages.
    final log = containerOf(tester).read(mqttMessageLogControllerProvider);
    final kinds = log.entries
        .whereType<MqttLogEvent>()
        .map((e) => e.kind)
        .toList();
    expect(
      kinds,
      containsAllInOrder([
        MqttEventKind.connecting,
        MqttEventKind.connected,
        MqttEventKind.subscribe,
      ]),
    );
    expect(log.messages, isNotEmpty);

    // Topic wildcard filter hides events and other topics.
    await tester.enterText(
      find.byKey(const Key('mqtt.monitor.topic')),
      'demo/sensors/+/humidity',
    );
    await tester.pumpAndSettle();
    final filtered = containerOf(tester).read(filteredLogProvider);
    expect(filtered, isNotEmpty);
    expect(
      filtered.every(
        (e) => e is MqttLogMessage && e.record.topic.endsWith('/humidity'),
      ),
      isTrue,
    );

    // Tap a row: the message opens with all payload views.
    await tester.tap(find.byKey(const Key('mqtt.monitor.row.0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('payload.view')), findsOneWidget);
    expect(find.text('Detected: Text (UTF-8)'), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('mqtt.monitor.sheet'))))
        .pop();
    await tester.pumpAndSettle();

    // Payload search.
    await tester.enterText(find.byKey(const Key('mqtt.monitor.topic')), '');
    await tester.enterText(find.byKey(const Key('mqtt.monitor.payload')), '°C');
    await tester.pumpAndSettle();
    expect(
      containerOf(tester)
          .read(filteredLogProvider)
          .every(
            (e) =>
                e is MqttLogMessage && e.record.topic.endsWith('temperature'),
          ),
      isTrue,
    );
    await tester.enterText(find.byKey(const Key('mqtt.monitor.payload')), '');

    // Errors only: nothing went wrong so far.
    await tester.tap(find.byKey(const Key('mqtt.monitor.errors')));
    await tester.pumpAndSettle();
    expect(find.text('No entry matches the filter.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mqtt.monitor.errors')));
    await tester.pumpAndSettle();

    // Export JSON Lines: readable back as a recording.
    await tester.tap(find.byKey(const Key('mqtt.monitor.export')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('As JSON Lines (recording)'));
    await tester.pumpAndSettle();
    final export = files.saved.single;
    expect(export.name, endsWith('.jsonl'));
    final recording = parseRecording(export.content);
    expect(recording.messages, isNotEmpty);
    expect(recording.skippedLines, greaterThan(0)); // the events

    // CSV export too.
    await tester.tap(find.byKey(const Key('mqtt.monitor.export')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('As CSV'));
    await tester.pumpAndSettle();
    expect(files.saved.last.content, startsWith('timestamp,direction,topic'));

    // Smaller buffer keeps the newest entries.
    await tester.tap(find.byKey(const Key('mqtt.monitor.size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1000').last);
    await tester.pumpAndSettle();
    expect(
      containerOf(tester).read(mqttMessageLogControllerProvider).capacity,
      1000,
    );

    await disconnect(tester);
    expect(
      containerOf(tester)
          .read(mqttMessageLogControllerProvider)
          .entries
          .whereType<MqttLogEvent>()
          .last
          .kind,
      MqttEventKind.disconnect,
    );
  });

  testWidgets('replay publishes a recording with prefix and timing', (
    tester,
  ) async {
    MqttLogMessage rec(String topic, String payload, int second) =>
        MqttLogMessage(
          MqttMessageRecord(
            direction: MqttDirection.received,
            topic: topic,
            payload: utf8.encode(payload),
            timestamp: DateTime(2026, 11, 20, 9, 0, second),
            retain: true,
          ),
        );
    files.toOpen.add(
      OpenedTextFile(
        name: 'session.jsonl',
        content: exportJsonLines([
          rec('plant/a', '1', 0),
          rec('plant/b', '2', 2),
          rec('plant/a', '3', 4),
        ]),
      ),
    );
    await openMqtt(tester);
    await connectDemo(tester);
    await tester.tapNavigation('Monitor');

    await tester.tap(find.byKey(const Key('mqtt.monitor.replay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('replay.load')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('session.jsonl: 3 messages, 2 topics, duration 4 s'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('replay.start')));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 messages will be published'), findsOneWidget);
    await tester.tap(find.byKey(const Key('replay.confirm')));
    await tester.pump();
    expect(find.byKey(const Key('mqtt.replay.banner')), findsOneWidget);

    // First message immediately, then after 2 s and 4 s (original timing).
    await tester.pump(const Duration(milliseconds: 300));
    List<MqttMessageRecord> sent() =>
        containerOf(tester)
            .read(mqttMessageLogControllerProvider)
            .messages
            .where((m) => m.direction == MqttDirection.sent)
            .toList();
    expect(sent().map((m) => m.topic), ['replay/plant/a']);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(sent(), hasLength(2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(sent().map((m) => m.topic), [
      'replay/plant/a',
      'replay/plant/b',
      'replay/plant/a',
    ]);
    // Retain stripped by default.
    expect(sent().every((m) => !m.retain), isTrue);
    expect(find.byKey(const Key('mqtt.replay.banner')), findsNothing);
    final events = containerOf(tester)
        .read(mqttMessageLogControllerProvider)
        .entries
        .whereType<MqttLogEvent>()
        .map((e) => e.kind);
    expect(
      events,
      containsAllInOrder([
        MqttEventKind.replayStarted,
        MqttEventKind.replayFinished,
      ]),
    );

    await disconnect(tester);
  });

  testWidgets(r'tools: broker info from $SYS, topic tester, converter', (
    tester,
  ) async {
    await openMqtt(tester);
    await connectDemo(tester);
    // The demo broker publishes uptime and clients every 10 s.
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();
    await tester.tapNavigation('Tools');

    expect(find.byKey(const Key('broker.info')), findsOneWidget);
    expect(find.text('ProtocollExplorer demo broker 1.0'), findsOneWidget);
    expect(find.byKey(const Key('broker.uptime')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('broker.clientsConnected')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    // Topic tester with explanations.
    await tester.tap(find.text('Topic tester'));
    await tester.pumpAndSettle();
    expect(find.text('matches'), findsOneWidget); // home/kitchen/temperature
    expect(find.text('no match: level 3 differs'), findsOneWidget);
    expect(
      find.text('no match: topic ends before filter level 3'),
      findsOneWidget,
    );
    expect(
      find.textContaining(r'topics starting with $'),
      findsNothing,
    ); // filter starts with home
    await tester.enterText(find.byKey(const Key('tester.filter')), '#');
    await tester.pumpAndSettle();
    expect(
      find.textContaining(r'topics starting with $ are never matched'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('tester.filter')), 'a/#/b');
    await tester.pumpAndSettle();
    expect(
      find.text('# is only allowed alone as the last level'),
      findsOneWidget,
    );

    // Payload converter: hex in, every format out, matrix below.
    await tester.tap(find.text('Payload converter'));
    await tester.pumpAndSettle();
    expect(find.text('QUgAAA=='), findsOneWidget);
    expect(find.text('65 72 0 0'), findsOneWidget);
    expect(find.text('{0x41, 0x48, 0x00, 0x00}'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('matrix.float32.abcd')),
        matching: find.text('12.5'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('converter.format')),
        matching: find.text('Text'),
      ),
    );
    await tester.enterText(find.byKey(const Key('converter.input')), 'Hi');
    await tester.pumpAndSettle();
    expect(find.text('48 69'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('converter.format')),
        matching: find.text('Hex'),
      ),
    );
    await tester.enterText(find.byKey(const Key('converter.input')), 'zz');
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Invalid input: Not a hex byte: zz'),
      findsOneWidget,
    );

    await disconnect(tester);
  });
}
