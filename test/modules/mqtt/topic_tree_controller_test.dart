// fakeAsync tests drive futures with elapse() instead of awaiting them.
// ignore_for_file: discarded_futures

import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topic_tree_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topic_tree_view.dart';

import '../../helpers/container.dart';

MqttProfile profile(String id) => MqttProfile(
  id: id,
  name: id,
  createdAt: DateTime(2026),
  config: const MqttConnectionConfig(host: 's', simulated: true),
);

void main() {
  test('high message rate: one UI update per flush interval', () {
    fakeAsync((async) {
      final container = createTestContainer();
      final controller = container.read(
        mqttConnectionControllerProvider.notifier,
      );
      var updates = 0;
      container.listen(mqttTopicTreeControllerProvider, (_, _) => updates++);
      controller.connect(profile('a'));
      async.flushMicrotasks();
      updates = 0;

      // 10 000 own publishes; the demo broker echoes nothing (no
      // subscription), so feed received records straight into traffic
      // through a subscription on a test topic.
      controller.putSubscription(const MqttSubscriptionSpec(filter: 'load/#'));
      async.flushMicrotasks();
      final payload = Uint8List.fromList(utf8.encode('1'));
      for (var i = 0; i < 10000; i++) {
        controller.publish(
          MqttOutgoingMessage(topic: 'load/t${i % 500}', payload: payload),
        );
      }
      async.elapse(const Duration(milliseconds: 100));
      expect(updates, 0, reason: 'still within the first interval');
      async.elapse(MqttTopicTreeController.flushInterval);
      final snapshot = container.read(mqttTopicTreeControllerProvider);
      expect(updates, 1);
      expect(snapshot.topicCount, 500);
      // Only received messages count (the echoes), not the sent records.
      expect(snapshot.messageCount, 10000);

      controller.disconnect();
      async.flushMicrotasks();
      container.dispose();
    });
  });

  test('connecting to another profile clears the tree', () {
    fakeAsync((async) {
      final container = createTestContainer();
      final controller = container.read(
        mqttConnectionControllerProvider.notifier,
      );
      container.listen(mqttTopicTreeControllerProvider, (_, _) {});
      controller.connect(
        profile('a').copyWith(
          config: const MqttConnectionConfig(
            host: 's',
            simulated: true,
            subscriptions: [MqttSubscriptionSpec(filter: 'demo/#')],
          ),
        ),
      );
      async.elapse(const Duration(seconds: 1));
      expect(
        container.read(mqttTopicTreeControllerProvider).topicCount,
        greaterThan(0),
      );
      controller.connect(profile('b'));
      async.elapse(const Duration(seconds: 1));
      expect(container.read(mqttTopicTreeControllerProvider).topicCount, 0);
      controller.disconnect();
      async.flushMicrotasks();
      container.dispose();
    });
  });

  testWidgets('a new value flashes the row, then fades', (tester) async {
    final tree = TopicTree()
      ..add(
        MqttMessageRecord(
          direction: MqttDirection.received,
          topic: 't',
          payload: Uint8List.fromList([1]),
          timestamp: DateTime.now(),
        ),
      );
    final row = tree.visibleRows(expanded: const {}).single;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(
          body: TopicTreeRow(
            row: row,
            selected: false,
            onToggle: () {},
            onSelect: () {},
          ),
        ),
      ),
    );
    Color color() => tester
        .widget<Material>(
          find
              .ancestor(
                of: find.byType(InkWell),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    expect(color().a, greaterThan(0.5));
    await tester.pump(TopicTreeRow.highlightDuration);
    await tester.pump();
    expect(color().a, 0);
  });
}
