import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_config.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_analysis.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';
import 'package:modbus_explorer/shared/interpretation/domain/value_formatter.dart';

/// A line of the monitor: a message or a connection event.
@immutable
sealed class MqttLogEntry {
  const new();

  DateTime get timestamp;
}

final class MqttLogMessage extends MqttLogEntry {
  const new(this.record);

  final MqttMessageRecord record;

  @override
  DateTime get timestamp => record.timestamp;
}

/// What the client did or what happened to the connection. The MQTT
/// packages do not expose raw packets, so these are the operations the
/// app performs (CONNECT/SUBSCRIBE/UNSUBSCRIBE/DISCONNECT) and their
/// outcomes.
enum MqttEventKind {
  connecting,
  connected,
  connectFailed,
  subscribe,
  unsubscribe,
  disconnect,
  connectionLost,
  reconnectScheduled,
  publishFailed,
  replayStarted,
  replayFinished;

  bool get isError =>
      this == connectFailed || this == connectionLost || this == publishFailed;

  /// Packet-like keyword for exports.
  String get keyword => switch (this) {
    connecting => 'CONNECT',
    connected => 'CONNACK',
    connectFailed => 'CONNACK-ERROR',
    subscribe => 'SUBSCRIBE',
    unsubscribe => 'UNSUBSCRIBE',
    disconnect => 'DISCONNECT',
    connectionLost => 'CONNECTION-LOST',
    reconnectScheduled => 'RECONNECT',
    publishFailed => 'PUBLISH-ERROR',
    replayStarted => 'REPLAY-START',
    replayFinished => 'REPLAY-END',
  };
}

final class MqttLogEvent extends MqttLogEntry {
  const new(this.kind, this.timestamp, {this.detail = ''});

  final MqttEventKind kind;
  @override
  final DateTime timestamp;

  /// Language-neutral detail (endpoint, filter, error text).
  final String detail;
}

/// Monitor filter. Events pass the topic/payload filters only when those
/// are empty; "only errors" shows error events alone.
@immutable
final class MonitorFilter {
  const new({
    this.topic = '',
    this.mode = TopicFilterMode.wildcard,
    this.payload = '',
    this.showReceived = true,
    this.showSent = true,
    this.showEvents = true,
    this.onlyRetained = false,
    this.onlyErrors = false,
  });

  final String topic;
  final TopicFilterMode mode;

  /// Substring of the payload text (case-insensitive) or of its hex form.
  final String payload;
  final bool showReceived;
  final bool showSent;
  final bool showEvents;
  final bool onlyRetained;
  final bool onlyErrors;

  bool get isActive =>
      topic.trim().isNotEmpty ||
      payload.trim().isNotEmpty ||
      !showReceived ||
      !showSent ||
      !showEvents ||
      onlyRetained ||
      onlyErrors;

  /// Error of an invalid topic filter (regex syntax, wildcard rules).
  String? get topicError => TopicTreeQuery(text: topic, mode: mode).error;

  MonitorFilter copyWith({
    String? topic,
    TopicFilterMode? mode,
    String? payload,
    bool? showReceived,
    bool? showSent,
    bool? showEvents,
    bool? onlyRetained,
    bool? onlyErrors,
  }) => MonitorFilter(
    topic: topic ?? this.topic,
    mode: mode ?? this.mode,
    payload: payload ?? this.payload,
    showReceived: showReceived ?? this.showReceived,
    showSent: showSent ?? this.showSent,
    showEvents: showEvents ?? this.showEvents,
    onlyRetained: onlyRetained ?? this.onlyRetained,
    onlyErrors: onlyErrors ?? this.onlyErrors,
  );

  /// Compiled predicate (regex etc. built once per filter change).
  bool Function(MqttLogEntry) matcher() {
    final topicMatch = TopicTreeQuery(text: topic, mode: mode).matcher();
    final needle = payload.trim().toLowerCase();
    final hexNeedle = needle.replaceAll(RegExp(r'0x|[\s,:]'), '');
    return (entry) {
      switch (entry) {
        case MqttLogEvent(:final kind):
          if (onlyErrors) return kind.isError;
          return showEvents && topicMatch == null && needle.isEmpty;
        case MqttLogMessage(:final record):
          if (onlyErrors) return false;
          final received = record.direction == MqttDirection.received;
          if (received ? !showReceived : !showSent) return false;
          if (onlyRetained && !record.retain) return false;
          if (topicMatch != null && !topicMatch(record.topic)) return false;
          if (needle.isEmpty) return true;
          final text = utf8.decode(record.payload, allowMalformed: true);
          if (text.toLowerCase().contains(needle)) return true;
          return hexNeedle.isNotEmpty &&
              RegExp(r'^[0-9a-f]+$').hasMatch(hexNeedle) &&
              formatHexBytes(
                record.payload,
                separator: '',
              ).toLowerCase().contains(hexNeedle);
      }
    };
  }
}

// ------------------------------------------------------------------ export

String _iso(DateTime t) => t.toUtc().toIso8601String();

String _payloadText(Uint8List payload) {
  final a = analyzeCached(payload);
  return a.kind == PayloadKind.binary || a.text == null
      ? formatHexBytes(payload)
      : a.text!;
}

/// Human-readable log, one line per entry.
String exportText(Iterable<MqttLogEntry> entries) {
  final out = StringBuffer();
  for (final e in entries) {
    switch (e) {
      case MqttLogMessage(:final record):
        final flags = [
          'QoS${record.qos.value}',
          if (record.retain) 'RETAIN',
          if (record.duplicate) 'DUP',
        ].join(' ');
        out.writeln(
          '${_iso(e.timestamp)} '
          '${record.direction == MqttDirection.received ? 'RX' : 'TX'} '
          '${record.topic} [$flags, ${record.payload.length} B] '
          '${_payloadText(record.payload).replaceAll('\n', r'\n')}',
        );
      case MqttLogEvent(:final kind, :final detail):
        out.writeln(
          '${_iso(e.timestamp)} -- ${kind.keyword} $detail'.trimRight(),
        );
    }
  }
  return out.toString();
}

String _csvField(String value) => RegExp(r'[",\n\r;]').hasMatch(value)
    ? '"${value.replaceAll('"', '""')}"'
    : value;

/// CSV with header; binary payloads as hex.
String exportCsv(Iterable<MqttLogEntry> entries) {
  final out = StringBuffer(
    'timestamp,direction,topic,qos,retain,dup,size,payload,event\n',
  );
  for (final e in entries) {
    final fields = switch (e) {
      MqttLogMessage(:final record) => [
        _iso(e.timestamp),
        if (record.direction == MqttDirection.received) 'rx' else 'tx',
        record.topic,
        '${record.qos.value}',
        '${record.retain}',
        '${record.duplicate}',
        '${record.payload.length}',
        _payloadText(record.payload),
        '',
      ],
      MqttLogEvent(:final kind, :final detail) => [
        _iso(e.timestamp),
        'event',
        '',
        '',
        '',
        '',
        '',
        detail,
        kind.keyword,
      ],
    };
    out.writeln(fields.map(_csvField).join(','));
  }
  return out.toString();
}

/// JSON Lines: one object per entry, payload as Base64 (lossless) plus
/// readable text where possible. Also the recording format for replay.
String exportJsonLines(Iterable<MqttLogEntry> entries) {
  final out = StringBuffer();
  for (final e in entries) {
    final Map<String, Object?> json;
    switch (e) {
      case MqttLogMessage(:final record):
        final text = analyzeCached(record.payload);
        final p = record.properties;
        json = {
          'ts': _iso(e.timestamp),
          'dir': record.direction == MqttDirection.received ? 'rx' : 'tx',
          'topic': record.topic,
          'qos': record.qos.value,
          'retain': record.retain,
          if (record.duplicate) 'dup': true,
          'payload_b64': base64.encode(record.payload),
          if (text.kind != PayloadKind.binary && text.text != null)
            'payload_text': text.text,
          if (!p.isEmpty)
            'properties': {
              'content_type': ?p.contentType,
              'response_topic': ?p.responseTopic,
              if (p.correlationData != null)
                'correlation_b64': base64.encode(p.correlationData!),
              if (p.messageExpiry != null)
                'message_expiry_s': p.messageExpiry!.inSeconds,
              if (p.payloadIsUtf8 != null) 'payload_utf8': p.payloadIsUtf8,
              if (p.userProperties.isNotEmpty)
                'user_properties': [
                  for (final (k, v) in p.userProperties) [k, v],
                ],
            },
        };
      case MqttLogEvent(:final kind, :final detail):
        json = {
          'ts': _iso(e.timestamp),
          'event': kind.keyword,
          'detail': detail,
        };
    }
    out.writeln(jsonEncode(json));
  }
  return out.toString();
}

// ---------------------------------------------------------------- replay

/// Messages read back from a JSON Lines recording.
@immutable
final class Recording {
  const new(this.messages, {this.skippedLines = 0});

  /// In file order (sorted by time when replaying).
  final List<MqttMessageRecord> messages;

  /// Lines that were events, empty or unreadable.
  final int skippedLines;

  Duration get duration => messages.length < 2
      ? Duration.zero
      : messages.last.timestamp.difference(messages.first.timestamp);

  int get topicCount => messages.map((m) => m.topic).toSet().length;
}

/// Parses [exportJsonLines] output; events and broken lines are counted
/// and skipped.
Recording parseRecording(String text) {
  final messages = <MqttMessageRecord>[];
  var skipped = 0;
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().isEmpty) continue;
    try {
      final json = jsonDecode(line) as Map<String, Object?>;
      if (json['topic'] is! String || json['payload_b64'] is! String) {
        skipped++;
        continue;
      }
      final p = json['properties'] as Map<String, Object?>?;
      messages.add(
        MqttMessageRecord(
          direction: json['dir'] == 'tx'
              ? MqttDirection.sent
              : MqttDirection.received,
          topic: json['topic']! as String,
          payload: base64.decode(json['payload_b64']! as String),
          timestamp: DateTime.parse(json['ts']! as String).toLocal(),
          qos: MqttQosLevel.fromValue(json['qos'] as int? ?? 0),
          retain: json['retain'] as bool? ?? false,
          duplicate: json['dup'] as bool? ?? false,
          properties: p == null
              ? MqttMessageProperties.none
              : MqttMessageProperties(
                  contentType: p['content_type'] as String?,
                  responseTopic: p['response_topic'] as String?,
                  correlationData: p['correlation_b64'] is String
                      ? base64.decode(p['correlation_b64']! as String)
                      : null,
                  messageExpiry: p['message_expiry_s'] is int
                      ? Duration(seconds: p['message_expiry_s']! as int)
                      : null,
                  payloadIsUtf8: p['payload_utf8'] as bool?,
                  userProperties: [
                    for (final pair
                        in p['user_properties'] as List? ?? const [])
                      if (pair is List && pair.length == 2)
                        ('${pair[0]}', '${pair[1]}'),
                  ],
                ),
        ),
      );
    } on Object {
      skipped++;
    }
  }
  return Recording(messages, skippedLines: skipped);
}

@immutable
final class ReplayOptions {
  const new({
    this.speed = 1,
    this.maxPause,
    this.topicPrefix = 'replay/',
    this.keepRetain = false,
    this.onlyReceived = true,
  });

  /// 1 = original timing, 2 = twice as fast …; 0 = no pauses.
  final double speed;

  /// Longer gaps are shortened to this (after [speed]).
  final Duration? maxPause;

  /// Prepended to every topic so replays do not overwrite live data.
  final String topicPrefix;

  /// Retain flags as recorded; off by default so a replay cannot leave
  /// retained values behind.
  final bool keepRetain;
  final bool onlyReceived;
}

/// One publish of a replay, [delay] after the previous one.
@immutable
final class ReplayStep {
  const new(this.delay, this.message);

  final Duration delay;
  final MqttOutgoingMessage message;
}

/// Messages in time order with their gaps scaled and capped.
List<ReplayStep> planReplay(Recording recording, ReplayOptions options) {
  final messages =
      recording.messages
          .where(
            (m) =>
                !options.onlyReceived || m.direction == MqttDirection.received,
          )
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final steps = <ReplayStep>[];
  DateTime? previous;
  for (final m in messages) {
    var gap = previous == null
        ? Duration.zero
        : m.timestamp.difference(previous);
    previous = m.timestamp;
    gap = options.speed <= 0
        ? Duration.zero
        : Duration(microseconds: (gap.inMicroseconds / options.speed).round());
    final cap = options.maxPause;
    if (cap != null && gap > cap) gap = cap;
    steps.add(
      ReplayStep(
        Duration(microseconds: max(0, gap.inMicroseconds)),
        MqttOutgoingMessage(
          topic: '${options.topicPrefix}${m.topic}',
          payload: m.payload,
          qos: m.qos,
          retain: options.keepRetain && m.retain,
          properties: m.properties,
        ),
      ),
    );
  }
  return steps;
}

// ----------------------------------------------------------- broker info

/// `$SYS` figures of the connected broker (Mosquitto names, plus EMQX's
/// `$SYS/brokers/<node>/…` for version and uptime).
@immutable
final class BrokerInfo {
  const new(this.values);

  factory fromTree(TopicTree tree) {
    final values = <BrokerFigure, (String, String)>{};
    final sys = tree.find(r'$SYS');
    if (sys == null) return BrokerInfo(values);
    void visit(TopicNode node) {
      final last = node.last;
      if (last != null) {
        final figure = BrokerFigure.forTopic(node.path);
        if (figure != null && !values.containsKey(figure)) {
          values[figure] = (
            node.path,
            utf8.decode(last.payload, allowMalformed: true).trim(),
          );
        }
      }
      node.children.forEach(visit);
    }

    visit(sys);
    return BrokerInfo(values);
  }

  /// Known figure → (topic, text value).
  final Map<BrokerFigure, (String, String)> values;

  bool get isEmpty => values.isEmpty;
}

enum BrokerFigure {
  version([r'$SYS/broker/version'], r'^\$SYS/brokers/[^/]+/version$'),
  uptime([r'$SYS/broker/uptime'], r'^\$SYS/brokers/[^/]+/uptime$'),
  clientsConnected([
    r'$SYS/broker/clients/connected',
    r'$SYS/broker/clients/active',
  ]),
  clientsTotal([r'$SYS/broker/clients/total']),
  clientsMaximum([r'$SYS/broker/clients/maximum']),
  subscriptions([r'$SYS/broker/subscriptions/count']),
  retained([r'$SYS/broker/retained messages/count']),
  messagesReceived([r'$SYS/broker/messages/received']),
  messagesSent([r'$SYS/broker/messages/sent']),
  loadReceived1m([r'$SYS/broker/load/messages/received/1min']),
  loadSent1m([r'$SYS/broker/load/messages/sent/1min']),
  bytesReceived([r'$SYS/broker/bytes/received']),
  bytesSent([r'$SYS/broker/bytes/sent']),
  heap([r'$SYS/broker/heap/current', r'$SYS/broker/heap/current size']);

  new(this.topics, [this.pattern]);

  final List<String> topics;
  final String? pattern;

  static BrokerFigure? forTopic(String topic) {
    for (final f in values) {
      if (f.topics.contains(topic)) return f;
      if (f.pattern case final p? when RegExp(p).hasMatch(topic)) return f;
    }
    return null;
  }
}
