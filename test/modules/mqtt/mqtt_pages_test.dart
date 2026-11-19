import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/storage/document_store.dart';
import 'package:modbus_explorer/core/storage/secret_store.dart';
import 'package:modbus_explorer/modules/mqtt/data/mqtt_profile_repository.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_message_log_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_profile_editor.dart';
import 'package:modbus_explorer/shared/profiles/profile_store.dart';

import '../../helpers/pump_app.dart';

void main() {
  late InMemorySecretStore secrets;

  setUp(() => secrets = InMemorySecretStore());

  Future<void> openMqtt(
    WidgetTester tester, {
    Size size = const Size(1400, 900),
  }) async {
    await tester.pumpModbusApp(size: size, secrets: secrets);
    await tester.tap(find.byKey(const Key('module.mqtt')));
    await tester.pumpAndSettle();
  }

  /// The editor's list is lazy: build the target before tapping it.
  Future<void> scrollEditorTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find
          .descendant(
            of: find.byType(MqttProfileEditor),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  Future<void> connectDemo(WidgetTester tester) async {
    await tester.tap(find.text('Demo-Broker (Simulator)'));
    await tester.pumpAndSettle();
  }

  testWidgets('demo broker: connect, status, disconnect', (tester) async {
    await openMqtt(tester);
    expect(find.text('Demo-Broker (Simulator)'), findsOneWidget);
    await connectDemo(tester);
    final card = find.byKey(const Key('mqtt.statusCard'));
    expect(
      find.descendant(of: card, matching: find.textContaining('Connected')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.textContaining('Client ID: pe-'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('MQTT 5.0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('mqtt.disconnect')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mqtt.reconnect')), findsOneWidget);
  });

  testWidgets(
    'editor: broker profile with TLS, password goes to the keychain',
    (tester) async {
      await openMqtt(tester);
      await tester.tap(find.byKey(const Key('mqtt.profiles.new')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('mqttEditor.name')),
        'Plant broker',
      );
      await tester.enterText(
        find.byKey(const Key('mqttEditor.host')),
        'broker.local',
      );
      // TLS switches the default port 1883 → 8883.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('mqttEditor.transport')),
          matching: find.text('TLS'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '8883'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('mqttEditor.username')),
        'plant',
      );
      await tester.enterText(
        find.byKey(const Key('mqttEditor.password')),
        'top-secret',
      );

      final accept = find.byKey(const Key('mqttEditor.acceptInvalid'));
      await scrollEditorTo(tester, accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mqttEditor.insecureWarning')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('mqttEditor.save')));
      await tester.pumpAndSettle();
      expect(find.text('Plant broker'), findsOneWidget);

      final doc = containerOf(
        tester,
      ).read(documentStoreProvider) as InMemoryDocumentStore;
      final json = doc.documents[ProfileStore.documentName]!;
      expect(json, isNot(contains('top-secret')));
      expect(json, contains('"hasPassword": true'));
      final id =
          ((jsonDecode(json) as Map<String, Object?>)['profiles']! as List)
                  .cast<Map<String, Object?>>()
                  .singleWhere((p) => p['name'] == 'Plant broker')['id']!
              as String;
      expect(
        secrets.values[MqttProfileRepository.passwordKey(id)],
        'top-secret',
      );
    },
  );

  testWidgets('editor validates required fields and the will topic', (
    tester,
  ) async {
    await openMqtt(tester);
    await tester.tap(find.byKey(const Key('mqtt.profiles.new')));
    await tester.pumpAndSettle();
    final will = find.byKey(const Key('mqttEditor.willEnabled'));
    await scrollEditorTo(tester, will);
    await tester.tap(will);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('mqttEditor.willTopic')),
      'status/#',
    );
    await tester.tap(find.byKey(const Key('mqttEditor.save')));
    await tester.pumpAndSettle();
    expect(
      find.text('+ and # are not allowed when publishing'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mqttEditor.save')),
      findsOneWidget,
    ); // still open
  });

  testWidgets('refused connection explains the CONNACK code', (tester) async {
    await openMqtt(tester);
    await tester.tap(find.byKey(const Key('mqtt.profiles.new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mqttEditor.name')), 'Denied');
    await tester.tap(find.text('Demo broker').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('mqttEditor.username')),
      'denied',
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('mqttEditor.version')),
        matching: find.text('MQTT 3.1.1'),
      ),
    );
    await tester.tap(find.byKey(const Key('mqttEditor.save')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Denied'));
    await tester.pumpAndSettle();
    expect(
      find.text('Broker refused: bad user name or password (code 4)'),
      findsOneWidget,
    );
  });

  testWidgets(
    'topics page: live messages, subscribe, publish, clear retained',
    (tester) async {
      await openMqtt(tester);
      await connectDemo(tester);
      await tester.tapNavigation('Topics');
      expect(find.byKey(const Key('mqtt.notConnected')), findsNothing);
      // Retained messages arrive immediately, live ones every second.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      // Newest first: the retained status (oldest) is scrolled out of view.
      final topics = containerOf(tester)
          .read(mqttMessageLogControllerProvider)
          .messages
          .map((m) => m.topic)
          .toSet();
      expect(
        topics,
        containsAll(['demo/plant/status', r'$SYS/broker/version']),
      );
      expect(find.text('demo/plant/line1/temperature'), findsWidgets);

      // Invalid filter.
      await tester.enterText(find.byKey(const Key('mqtt.sub.filter')), 'a/#/b');
      await tester.tap(find.byKey(const Key('mqtt.sub.add')));
      await tester.pumpAndSettle();
      expect(
        find.text('# is only allowed alone as the last level'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('mqtt.sub.filter')),
        'test/+',
      );
      await tester.tap(find.byKey(const Key('mqtt.sub.add')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mqtt.sub.test/+')), findsOneWidget);

      // '#' asks first.
      await tester.tap(find.byKey(const Key('mqtt.sub.all')));
      await tester.pumpAndSettle();
      expect(find.textContaining('thousands of messages'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mqtt.sub.#')), findsNothing);

      // Publish hex payload; the own subscription echoes it back.
      await tester.enterText(
        find.byKey(const Key('mqtt.pub.topic')),
        'test/raw',
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('mqtt.pub.format')),
          matching: find.text('Hex'),
        ),
      );
      await tester.enterText(find.byKey(const Key('mqtt.pub.payload')), 'zz');
      await tester.ensureVisible(find.byKey(const Key('mqtt.pub.send')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mqtt.pub.send')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Invalid payload'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('mqtt.pub.payload')),
        '00 2A',
      );
      await tester.tap(find.byKey(const Key('mqtt.pub.send')));
      await tester.pump(MqttMessageLogController.flushInterval * 2);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Published to “test/raw” (2 bytes)'),
        findsOneWidget,
      );
      final log = containerOf(tester)
          .read(mqttMessageLogControllerProvider)
          .messages;
      final raw = log.where((m) => m.topic == 'test/raw').toList();
      expect(raw.map((m) => m.direction), [
        MqttDirection.sent,
        MqttDirection.received,
      ]);
      expect(raw.first.payload, [0x00, 0x2A]);

      // Publishing to a known topic asks first.
      await tester.enterText(
        find.byKey(const Key('mqtt.pub.topic')),
        'demo/plant/status',
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('mqtt.pub.format')),
          matching: find.text('Text'),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('mqtt.pub.payload')),
        'stopped',
      );
      await tester.tap(find.byKey(const Key('mqtt.pub.send')));
      await tester.pumpAndSettle();
      expect(find.text('Overwrite an existing topic?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Clearing a retained message needs confirmation.
      await tester.ensureVisible(
        find.byKey(const Key('mqtt.pub.clearRetained')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mqtt.pub.clearRetained')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mqtt.clearRetainedConfirm')));
      await tester.pumpAndSettle();
      expect(
        find.text('Retained message on “demo/plant/status” cleared'),
        findsOneWidget,
      );
      final cleared = containerOf(tester)
          .read(mqttMessageLogControllerProvider)
          .messages
          .lastWhere((m) => m.direction == MqttDirection.sent);
      expect(cleared.payload, isEmpty);
      expect(cleared.retain, isTrue);

      await tester.tapNavigation('Connection');
      await tester.tap(find.byKey(const Key('mqtt.disconnect')));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('phone: topics page uses tabs', (tester) async {
    await openMqtt(tester, size: const Size(390, 844));
    await connectDemo(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Topics'),
      ),
    );
    await tester.pumpAndSettle();
    for (final tab in ['Subscriptions', 'Publish', 'Messages']) {
      await tester.tap(find.widgetWithText(Tab, tab));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('mqtt.messageCount')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Connection'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mqtt.disconnect')));
    await tester.pumpAndSettle();
  });
}
