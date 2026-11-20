import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_log.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_filter.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';
import 'package:modbus_explorer/shared/interpretation/domain/hex_bytes.dart';

final t0 = DateTime.utc(2026, 11, 20, 8);

MqttLogMessage msg(
  String topic,
  Object payload, {
  MqttDirection dir = MqttDirection.received,
  bool retain = false,
  int second = 0,
  MqttMessageProperties properties = MqttMessageProperties.none,
}) => MqttLogMessage(
  MqttMessageRecord(
    direction: dir,
    topic: topic,
    payload: payload is String
        ? Uint8List.fromList(utf8.encode(payload))
        : Uint8List.fromList(payload as List<int>),
    timestamp: t0.add(Duration(seconds: second)),
    qos: MqttQosLevel.atLeastOnce,
    retain: retain,
    properties: properties,
  ),
);

MqttLogEvent event(MqttEventKind kind, [String detail = '']) =>
    MqttLogEvent(kind, t0, detail: detail);

void main() {
  group('monitor filter', () {
    final entries = <MqttLogEntry>[
      msg('home/kitchen/temp', '{"t":21}'),
      msg('home/garage/door', 'open', retain: true),
      msg('cmd/light', 'on', dir: MqttDirection.sent),
      msg('raw/bytes', [0xDE, 0xAD, 0xBE, 0xEF]),
      event(MqttEventKind.connected, 'pe-1'),
      event(MqttEventKind.connectionLost),
    ];
    List<String> run(MonitorFilter f) {
      final m = f.matcher();
      return [
        for (final e in entries.where(m))
          switch (e) {
            MqttLogMessage(:final record) => record.topic,
            MqttLogEvent(:final kind) => kind.name,
          },
      ];
    }

    test('everything by default', () {
      expect(run(const MonitorFilter()), hasLength(6));
      expect(const MonitorFilter().isActive, isFalse);
    });

    test('topic wildcard hides events', () {
      expect(run(const MonitorFilter(topic: 'home/#')), [
        'home/kitchen/temp',
        'home/garage/door',
      ]);
    });

    test('topic regex and text mode', () {
      expect(
        run(
          const MonitorFilter(
            topic: r'(door|light)$',
            mode: TopicFilterMode.regex,
          ),
        ),
        ['home/garage/door', 'cmd/light'],
      );
      expect(
        run(const MonitorFilter(topic: 'KITCHEN', mode: TopicFilterMode.text)),
        ['home/kitchen/temp'],
      );
      expect(
        const MonitorFilter(topic: '(', mode: TopicFilterMode.regex).topicError,
        isNotNull,
      );
    });

    test('payload text and hex search', () {
      expect(run(const MonitorFilter(payload: '"T":21')), [
        'home/kitchen/temp',
      ]);
      expect(run(const MonitorFilter(payload: 'ad be')), ['raw/bytes']);
      expect(run(const MonitorFilter(payload: '0xBEEF')), ['raw/bytes']);
    });

    test('direction, retained, errors, events', () {
      expect(run(const MonitorFilter(showReceived: false)), [
        'cmd/light',
        'connected',
        'connectionLost',
      ]);
      expect(run(const MonitorFilter(onlyRetained: true, showEvents: false)), [
        'home/garage/door',
      ]);
      expect(run(const MonitorFilter(onlyErrors: true)), ['connectionLost']);
      expect(run(const MonitorFilter(showEvents: false)), hasLength(4));
    });
  });

  group('export', () {
    final entries = <MqttLogEntry>[
      msg('a/b', 'hello, "world"\nline 2', retain: true),
      msg('bin', [0x00, 0xFF], dir: MqttDirection.sent, second: 1),
      event(MqttEventKind.subscribe, 'a/# QoS 1'),
    ];

    test('text: one line per entry, binary as hex', () {
      final lines = exportText(entries).trim().split('\n');
      expect(lines, hasLength(3));
      expect(
        lines[0],
        startsWith('2026-11-20T08:00:00.000Z RX a/b [QoS1 RETAIN, 21 B] hello'),
      );
      expect(lines[0], contains(r'\nline 2'));
      expect(lines[1], endsWith('00 FF'));
      expect(lines[2], endsWith('-- SUBSCRIBE a/# QoS 1'));
    });

    test('CSV quotes separators, quotes and newlines', () {
      final csv = exportCsv(entries).split('\n');
      expect(
        csv.first,
        'timestamp,direction,topic,qos,retain,dup,size,payload,event',
      );
      expect(exportCsv(entries), contains('"hello, ""world""\nline 2"'));
      expect(exportCsv(entries), contains(',event,,,,,,a/# QoS 1,SUBSCRIBE'));
    });

    test('JSON Lines round trip through the recording parser', () {
      final props = MqttMessageProperties(
        contentType: 'text/plain',
        correlationData: Uint8List.fromList([1, 2]),
        messageExpiry: const Duration(seconds: 30),
        userProperties: const [('k', 'v')],
      );
      final jsonl = exportJsonLines([
        ...entries,
        msg('p', 'x', properties: props, second: 2),
      ]);
      final lines = jsonl.trim().split('\n');
      expect(lines, hasLength(4));
      final first = jsonDecode(lines[0]) as Map<String, Object?>;
      expect(first['payload_text'], 'hello, "world"\nline 2');
      final second = jsonDecode(lines[1]) as Map<String, Object?>;
      expect(second.containsKey('payload_text'), isFalse);
      expect(second['payload_b64'], base64.encode([0, 255]));

      final recording = parseRecording('$jsonl\nnot json\n');
      expect(recording.messages, hasLength(3));
      expect(recording.skippedLines, 2); // the event + the broken line
      final bin = recording.messages[1];
      expect(bin.direction, MqttDirection.sent);
      expect(bin.payload, [0, 255]);
      final p = recording.messages[2].properties;
      expect(p.contentType, 'text/plain');
      expect(p.correlationData, [1, 2]);
      expect(p.messageExpiry, const Duration(seconds: 30));
      expect(p.userProperties, [('k', 'v')]);
      expect(recording.duration, const Duration(seconds: 2));
      expect(recording.topicCount, 3);
    });
  });

  group('replay plan', () {
    final recording = Recording([
      msg('a', '1', second: 10).record,
      msg('b', '2', retain: true).record,
      msg('c', '3', second: 40, dir: MqttDirection.sent).record,
      msg('d', '4', second: 100).record,
    ]);

    test('sorted by time, original gaps, prefix, retain stripped', () {
      final steps = planReplay(recording, const ReplayOptions());
      expect(steps.map((s) => s.message.topic), [
        'replay/b',
        'replay/a',
        'replay/d',
      ]);
      expect(steps.map((s) => s.delay.inSeconds), [0, 10, 90]);
      expect(steps.first.message.retain, isFalse);
    });

    test('speed, pause cap, keep retain, include sent', () {
      final steps = planReplay(
        recording,
        const ReplayOptions(
          speed: 2,
          maxPause: Duration(seconds: 20),
          topicPrefix: '',
          keepRetain: true,
          onlyReceived: false,
        ),
      );
      expect(steps.map((s) => s.message.topic), ['b', 'a', 'c', 'd']);
      expect(steps.map((s) => s.delay.inSeconds), [0, 5, 15, 20]);
      expect(steps.first.message.retain, isTrue);
      expect(
        planReplay(
          recording,
          const ReplayOptions(speed: 0),
        ).every((s) => s.delay == Duration.zero),
        isTrue,
      );
    });
  });

  group('broker info', () {
    test(r'Mosquitto $SYS figures', () {
      final tree = TopicTree();
      for (final (topic, value) in [
        (r'$SYS/broker/version', 'mosquitto version 2.0.20'),
        (r'$SYS/broker/uptime', '1234 seconds'),
        (r'$SYS/broker/clients/connected', '3'),
        (r'$SYS/broker/load/messages/received/1min', '12.5'),
        (r'$SYS/broker/retained messages/count', '42'),
        (r'$SYS/broker/unknown', 'x'),
        ('normal/topic', 'y'),
      ]) {
        tree.add(msg(topic, value).record);
      }
      final info = BrokerInfo.fromTree(tree);
      expect(info.values[BrokerFigure.version]!.$2, 'mosquitto version 2.0.20');
      expect(info.values[BrokerFigure.clientsConnected]!.$2, '3');
      expect(info.values[BrokerFigure.loadReceived1m]!.$2, '12.5');
      expect(info.values[BrokerFigure.retained]!.$2, '42');
      expect(info.values, hasLength(5));
    });

    test(r'EMQX node topics and no $SYS at all', () {
      final tree = TopicTree()
        ..add(msg(r'$SYS/brokers/emqx@node1/version', '5.8.0').record);
      expect(
        BrokerInfo.fromTree(tree).values[BrokerFigure.version]!.$1,
        r'$SYS/brokers/emqx@node1/version',
      );
      expect(BrokerInfo.fromTree(TopicTree()).isEmpty, isTrue);
    });
  });

  group('topic tester explanations', () {
    test('reasons', () {
      expect(explainMatch('a/+/c', 'a/b/c').reason, MatchReason.match);
      expect(explainMatch('a/#', 'a').reason, MatchReason.matchMultiLevel);
      final mismatch = explainMatch('a/+/c', 'a/b/d');
      expect(mismatch.reason, MatchReason.levelMismatch);
      expect(mismatch.level, 2);
      expect(explainMatch('a/b/c', 'a/b').reason, MatchReason.topicTooShort);
      expect(explainMatch('a/b', 'a/b/c').reason, MatchReason.topicTooLong);
      expect(explainMatch('#', r'$SYS/x').reason, MatchReason.dollarTopic);
      expect(
        explainMatch('a/#/b', 'a').filterError,
        TopicError.misplacedMultiLevel,
      );
      expect(explainMatch('a', 'a/+').topicError, TopicError.wildcard);
      expect(explainMatch('a/+', 'a/x').matches, isTrue);
    });

    test('agrees with topicMatches', () {
      for (final (f, t) in [
        ('a/+/c', 'a/b/c'),
        ('a/#', 'a/b/c'),
        ('+/+', '/x'),
        ('#', r'$SYS/a'),
        (r'$SYS/#', r'$SYS/a'),
        ('a/b', 'a/b/c'),
      ]) {
        expect(explainMatch(f, t).matches, topicMatches(f, t), reason: '$f $t');
      }
    });
  });

  test('shared hex parser', () {
    expect(parseHexBytes('41 20 00 00').bytes, [0x41, 0x20, 0, 0]);
    expect(parseHexBytes('0x41200000').bytes, [0x41, 0x20, 0, 0]);
    expect(parseHexBytes('41:20,a;0x0b').bytes, [0x41, 0x20, 0x0A, 0x0B]);
    expect(parseHexBytes('ABC').invalidToken, 'ABC');
    expect(parseHexBytes('zz 12').invalidToken, 'zz');
    expect(parseHexBytes('').bytes, isEmpty);
  });
}
