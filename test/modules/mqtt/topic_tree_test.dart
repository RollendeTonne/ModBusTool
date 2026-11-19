import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';

MqttMessageRecord msg(String topic, [String payload = 'x', int second = 0]) =>
    MqttMessageRecord(
      direction: MqttDirection.received,
      topic: topic,
      payload: Uint8List.fromList(utf8.encode(payload)),
      timestamp: DateTime(2026, 1, 1, 0, 0, second),
    );

List<String> paths(List<TopicRow> rows) => [for (final r in rows) r.node.path];

void main() {
  group('building', () {
    test('splits levels and aggregates counts', () {
      final tree = TopicTree()
        ..add(msg('home/kitchen/temp', '21'))
        ..add(msg('home/kitchen/temp', '22'))
        ..add(msg('home/kitchen/hum', '40'))
        ..add(msg('home', 'online'))
        ..add(msg('car/speed', '0'));
      expect(tree.topicCount, 4);
      expect(tree.messageCount, 5);

      final home = tree.find('home')!;
      expect(home.isTopic, isTrue);
      expect(home.messageCount, 1);
      expect(home.totalMessages, 4);
      expect(home.descendantTopics, 2);
      expect(home.childCount, 1);

      final kitchen = tree.find('home/kitchen')!;
      expect(kitchen.isTopic, isFalse);
      expect(kitchen.descendantTopics, 2);
      expect(kitchen.depth, 1);

      final temp = tree.find('home/kitchen/temp')!;
      expect(utf8.decode(temp.last!.payload), '22');
      expect(temp.messageCount, 2);
      expect(temp.path, 'home/kitchen/temp');
    });

    test('empty levels are kept as levels', () {
      final tree = TopicTree()
        ..add(msg('/leading'))
        ..add(msg('a//b'))
        ..add(msg('trailing/'));
      expect(tree.find('/leading')!.depth, 1);
      expect(tree.find('')!.name, '');
      expect(tree.find('a/')!.child('b')!.path, 'a//b');
      expect(tree.find('trailing/')!.isTopic, isTrue);
      expect(tree.topicCount, 3);
    });

    test('change tracking: same payload is no change', () {
      final tree = TopicTree()
        ..add(msg('t', 'a', 1))
        ..add(msg('t', 'a', 2));
      final node = tree.find('t')!;
      expect(node.hasChanged, isFalse);
      final version = node.changeVersion;
      tree.add(msg('t', 'b', 3));
      expect(node.hasChanged, isTrue);
      expect(node.changeVersion, version + 1);
      expect(node.lastChangedAt, DateTime(2026, 1, 1, 0, 0, 3));
      expect(tree.root.subtreeHasChanged, isTrue);
    });

    test('lastActivity propagates to ancestors', () {
      final tree = TopicTree()
        ..add(msg('a/b', 'x', 5))
        ..add(msg('a/c', 'x', 9));
      expect(tree.find('a')!.lastActivity, DateTime(2026, 1, 1, 0, 0, 9));
    });

    test('clear empties everything', () {
      final tree = TopicTree()
        ..add(msg('a/b'))
        ..clear();
      expect(tree.topicCount, 0);
      expect(tree.messageCount, 0);
      expect(tree.find('a'), isNull);
      expect(tree.visibleRows(expanded: const {}), isEmpty);
    });
  });

  group('sorting', () {
    test('natural, case-insensitive order', () {
      final tree = TopicTree();
      for (final t in ['s10', 'S2', 's1', 'b', 'A', r'$SYS']) {
        tree.add(msg(t));
      }
      expect(paths(tree.visibleRows(expanded: const {})), [
        r'$SYS',
        'A',
        'b',
        's1',
        'S2',
        's10',
      ]);
    });
  });

  group('visible rows', () {
    late TopicTree tree;
    setUp(() {
      tree = TopicTree()
        ..add(msg('home/kitchen/temp', '21'))
        ..add(msg('home/kitchen/temp', '22'))
        ..add(msg('home/garage/door', 'closed'))
        ..add(msg(r'$SYS/broker/uptime', '5'))
        ..add(msg('car/speed', '0'));
    });

    test('collapsed shows only the first level', () {
      expect(paths(tree.visibleRows(expanded: const {})), [
        r'$SYS',
        'car',
        'home',
      ]);
    });

    test('expanded paths reveal their children', () {
      final rows = tree.visibleRows(expanded: {'home', 'home/kitchen'});
      expect(paths(rows), [
        r'$SYS',
        'car',
        'home',
        'home/garage',
        'home/kitchen',
        'home/kitchen/temp',
      ]);
      expect(rows[2].expanded, isTrue);
      expect(rows[3].expanded, isFalse);
    });

    test(r'$SYS can be hidden', () {
      final rows = tree.visibleRows(
        expanded: const {},
        query: const TopicTreeQuery(showSys: false),
      );
      expect(paths(rows), ['car', 'home']);
    });

    test('text filter opens ancestors of matches', () {
      final rows = tree.visibleRows(
        expanded: const {},
        query: const TopicTreeQuery(text: 'TEMP'),
      );
      expect(paths(rows), ['home', 'home/kitchen', 'home/kitchen/temp']);
      expect(rows.first.forcedOpen, isTrue);
    });

    test('wildcard filter uses MQTT matching', () {
      final rows = tree.visibleRows(
        expanded: const {},
        query: const TopicTreeQuery(
          text: 'home/+/door',
          mode: TopicFilterMode.wildcard,
        ),
      );
      expect(paths(rows).last, 'home/garage/door');
      expect(paths(rows), hasLength(3));
      // `#` does not match $SYS.
      final all = tree.visibleRows(
        expanded: const {},
        query: const TopicTreeQuery(text: '#', mode: TopicFilterMode.wildcard),
      );
      expect(paths(all), isNot(contains(r'$SYS')));
    });

    test('regex filter, invalid regex shows nothing with an error', () {
      final rows = tree.visibleRows(
        expanded: const {},
        query: const TopicTreeQuery(
          text: r'(speed|uptime)$',
          mode: TopicFilterMode.regex,
        ),
      );
      expect(paths(rows), containsAll(['car/speed', r'$SYS/broker/uptime']));
      const broken = TopicTreeQuery(text: '(', mode: TopicFilterMode.regex);
      expect(broken.error, isNotNull);
      expect(tree.visibleRows(expanded: const {}, query: broken), isEmpty);
    });

    test('only changed topics', () {
      final rows = tree.visibleRows(
        expanded: const {},
        query: const TopicTreeQuery(onlyChanged: true),
      );
      expect(paths(rows), ['home', 'home/kitchen', 'home/kitchen/temp']);
    });

    test('allBranchPaths expands everything', () {
      final rows = tree.visibleRows(expanded: tree.allBranchPaths());
      expect(rows, hasLength(tree.find('home')!.descendantTopics + 8));
    });
  });

  group('performance', () {
    test('10 000 topics, 200 000 messages: insert and flatten stay fast', () {
      final tree = TopicTree();
      final payload = Uint8List.fromList(utf8.encode('{"v":1}'));
      final topics = [
        for (var site = 0; site < 10; site++)
          for (var device = 0; device < 100; device++)
            for (var point = 0; point < 10; point++)
              'plant/site$site/device$device/point$point',
      ];
      final now = DateTime(2026);
      final insert = Stopwatch()..start();
      for (var i = 0; i < 200000; i++) {
        tree.add(
          MqttMessageRecord(
            direction: MqttDirection.received,
            topic: topics[i % topics.length],
            payload: payload,
            timestamp: now,
          ),
        );
      }
      insert.stop();
      expect(tree.topicCount, 10000);
      expect(tree.messageCount, 200000);

      final expanded = tree.allBranchPaths();
      final flatten = Stopwatch()..start();
      final rows = tree.visibleRows(expanded: expanded);
      flatten.stop();
      expect(rows, hasLength(1 + 10 + 1000 + 10000));

      final filter = Stopwatch()..start();
      final filtered = tree.visibleRows(
        expanded: const {},
        query: const TopicTreeQuery(text: 'device42/point7'),
      );
      filter.stop();
      expect(filtered.last.node.path, endsWith('device42/point7'));

      // Timings for DECISIONS.md.
      // ignore: avoid_print
      print(
        'insert 200k: ${insert.elapsedMilliseconds} ms, '
        'flatten 11k rows: ${flatten.elapsedMilliseconds} ms, '
        'filter: ${filter.elapsedMilliseconds} ms',
      );
      // Generous bounds for slow CI machines; locally far below.
      expect(insert.elapsedMilliseconds, lessThan(3000));
      expect(flatten.elapsedMilliseconds, lessThan(500));
      expect(filter.elapsedMilliseconds, lessThan(500));
    });
  });
}
