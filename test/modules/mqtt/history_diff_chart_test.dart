import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/mqtt/domain/chart_field.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_diff.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_statistics.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';
import 'package:modbus_explorer/shared/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/shared/interpretation/domain/data_type.dart';

final t0 = DateTime(2026, 11, 19, 12);

MqttMessageRecord msg(
  String topic,
  Object payload, {
  Duration at = Duration.zero,
}) => MqttMessageRecord(
  direction: MqttDirection.received,
  topic: topic,
  payload: payload is String
      ? Uint8List.fromList(utf8.encode(payload))
      : Uint8List.fromList(payload as List<int>),
  timestamp: t0.add(at),
);

List<String> texts(TopicNode n) => [
  for (final r in n.history) utf8.decode(r.payload),
];

void main() {
  group('history', () {
    test('keeps the last N messages per topic', () {
      final tree = TopicTree(historyPerTopic: 3);
      for (var i = 0; i < 5; i++) {
        tree.add(msg('a', '$i'));
      }
      final node = tree.find('a')!;
      expect(texts(node), ['2', '3', '4']);
      expect(tree.historyCount, 3);
      expect(node.messageCount, 5);
    });

    test('memory budget evicts the globally oldest entries first', () {
      const size = 10 + TopicTree.entryOverhead;
      final tree = TopicTree(historyBudgetBytes: size * 4);
      final payload = 'x' * 10;
      tree
        ..add(msg('quiet', payload))
        ..add(msg('busy', payload))
        ..add(msg('busy', payload))
        ..add(msg('busy', payload))
        ..add(msg('busy', payload));
      expect(tree.historyBytes, lessThanOrEqualTo(size * 4));
      expect(tree.find('quiet')!.historyLength, 0);
      expect(tree.find('busy')!.historyLength, 4);
      // The last value survives eviction.
      expect(tree.find('quiet')!.last, isNotNull);
    });

    test('stale queue entries are compacted', () {
      final tree = TopicTree(historyPerTopic: 1);
      for (var i = 0; i < 5000; i++) {
        tree.add(msg('t', '$i'));
      }
      expect(tree.historyCount, 1);
      // Without compaction the eviction queue would hold 5000 entries;
      // indirectly visible through a tight budget still working.
      tree.setHistoryLimits(perTopic: 1, budgetBytes: 0);
      expect(tree.historyCount, 0);
      expect(tree.historyBytes, 0);
    });

    test('new limits apply to existing histories', () {
      final tree = TopicTree(historyPerTopic: 10);
      for (var i = 0; i < 10; i++) {
        tree
          ..add(msg('a', '$i'))
          ..add(msg('b/c', '$i'));
      }
      tree.setHistoryLimits(perTopic: 2, budgetBytes: 1 << 20);
      expect(texts(tree.find('a')!), ['8', '9']);
      expect(texts(tree.find('b/c')!), ['8', '9']);
      expect(tree.historyCount, 4);
      tree.clear();
      expect(tree.historyCount, 0);
      expect(tree.historyBytes, 0);
    });
  });

  group('statistics', () {
    test('rates, sizes and age', () {
      final tree = TopicTree();
      for (var i = 0; i < 11; i++) {
        tree.add(msg('s', 'x' * (i + 1), at: Duration(seconds: i * 2)));
      }
      final stats = TopicStatistics.of(
        tree.find('s')!,
        t0.add(const Duration(seconds: 25)),
      );
      expect(stats.messageCount, 11);
      expect(stats.overallRate, closeTo(0.5, 1e-9)); // 10 gaps in 20 s
      expect(stats.recentRate, closeTo(11 / 60, 1e-9));
      expect(stats.recentRateIsLowerBound, isFalse);
      expect(stats.averageSize, 6);
      expect(stats.minSize, 1);
      expect(stats.maxSize, 11);
      expect(stats.sinceLast, const Duration(seconds: 5));
      expect(stats.firstSeen, t0);
    });

    test('truncated history makes the recent rate a lower bound', () {
      final tree = TopicTree(historyPerTopic: 5);
      for (var i = 0; i < 20; i++) {
        tree.add(msg('s', '1', at: Duration(seconds: i)));
      }
      final stats = TopicStatistics.of(
        tree.find('s')!,
        t0.add(const Duration(seconds: 20)),
      );
      expect(stats.recentRateIsLowerBound, isTrue);
      expect(stats.historyLength, 5);
    });

    test('a single message has no overall rate', () {
      final tree = TopicTree()..add(msg('s', '1'));
      expect(TopicStatistics.of(tree.find('s')!, t0).overallRate, isNull);
    });
  });

  group('diff', () {
    test('JSON changes, additions, removals, nested and arrays', () {
      final a = jsonDecode(
        '{"t": 21, "unit": "C", "tags": [1, 2], "o": {"x": 1}}',
      );
      final b = jsonDecode(
        '{"t": 22, "tags": [1, 3, 4], "o": {"x": 1}, "new": true}',
      );
      final changes = diffJson(a, b);
      String describe(JsonChange c) =>
          '${c.kind.name} ${c.pathText} ${c.before} ${c.after}';
      expect(changes.map(describe), [
        r'added $.new null true',
        r'changed $.t 21 22',
        r'changed $.tags[1] 2 3',
        r'added $.tags[2] null 4',
        r'removed $.unit C null',
      ]);
      expect(diffJson(a, a), isEmpty);
      expect(
        diffJson(
          {'v': 1},
          {
            'v': {'n': 1},
          },
        ).single.kind,
        ChangeKind.changed,
      );
    });

    test('line diff keeps common lines', () {
      final lines = diffLines('a\nb\nc\nd', 'a\nc\nd\ne');
      expect(lines.map((l) => '${l.op.name}:${l.text}'), [
        'same:a',
        'removed:b',
        'same:c',
        'same:d',
        'added:e',
      ]);
      expect(diffLines('x', 'x').single.op, LineOp.same);
      // Fallback for huge inputs.
      expect(
        diffLines(
          'a\nb',
          'a\nc',
          maxCells: 1,
        ).where((l) => l.op == LineOp.same),
        isEmpty,
      );
    });

    test('byte diff merges runs and handles length changes', () {
      final runs = diffBytes(
        Uint8List.fromList([1, 2, 3, 4, 5]),
        Uint8List.fromList([1, 9, 9, 4, 5, 6, 7]),
      );
      expect(runs, hasLength(2));
      expect(runs[0].offset, 1);
      expect(runs[0].before, [2, 3]);
      expect(runs[0].after, [9, 9]);
      expect(runs[1].offset, 5);
      expect(runs[1].before, isEmpty);
      expect(runs[1].after, [6, 7]);
      expect(diffBytes(Uint8List(3), Uint8List(3)), isEmpty);
    });

    test('mode follows the payload types', () {
      Uint8List b(String s) => Uint8List.fromList(utf8.encode(s));
      expect(diffModeFor(b('{"a":1}'), b('{"a":2}')), DiffMode.json);
      expect(diffModeFor(b('{"a":1}'), b('broken {')), DiffMode.text);
      expect(diffModeFor(b('on'), b('off')), DiffMode.text);
      expect(
        diffModeFor(Uint8List.fromList([0, 1]), Uint8List.fromList([0, 2])),
        DiffMode.bytes,
      );
    });
  });

  group('chart fields', () {
    test('JSON path accepts numbers, numeric strings and booleans', () {
      const field = JsonPathField(['s', 'v']);
      expect(field.extract(msg('t', '{"s":{"v":21.5}}')), 21.5);
      expect(field.extract(msg('t', '{"s":{"v":"7"}}')), 7);
      expect(field.extract(msg('t', '{"s":{"v":true}}')), 1);
      expect(field.extract(msg('t', '{"s":{"v":"on"}}')), isNull);
      expect(field.extract(msg('t', '{"s":{}}')), isNull);
      expect(field.extract(msg('t', 'not json')), isNull);
      expect(field.label, r'$.s.v');
    });

    test('binary field decodes with the shared engine', () {
      const be = BinaryField(
        offset: 1,
        type: DataType.float32,
        order: ByteOrderFamily.abcd,
      );
      expect(be.extract(msg('t', [0xFF, 0x41, 0x48, 0x00, 0x00])), 12.5);
      expect(be.extract(msg('t', [0xFF, 0x41])), isNull); // too short
      const le = BinaryField(
        offset: 0,
        type: DataType.uint16,
        order: ByteOrderFamily.dcba,
      );
      expect(le.extract(msg('t', [0x01, 0x02])), 0x0201);
      expect(le.label, 'UINT16 DCBA @ 0');
    });

    test('series skips messages without a value; default field', () {
      final history = [
        msg('t', '1'),
        msg('t', 'n/a', at: const Duration(seconds: 1)),
        msg('t', '3.5', at: const Duration(seconds: 2)),
      ];
      final points = chartSeries(history, const TextNumberField());
      expect(points.map((p) => p.value), [1, 3.5]);
      expect(points.last.time, t0.add(const Duration(seconds: 2)));
      expect(defaultChartField(msg('t', ' 42 ')), isA<TextNumberField>());
      expect(defaultChartField(msg('t', '{"a":1}')), isNull);
      expect(defaultChartField(null), isNull);
    });
  });
}
