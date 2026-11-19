import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';

/// Figures for one topic at a point in time.
@immutable
final class TopicStatistics {
  const new({
    required this.messageCount,
    required this.firstSeen,
    required this.lastSeen,
    required this.averageSize,
    required this.minSize,
    required this.maxSize,
    required this.overallRate,
    required this.recentRate,
    required this.recentRateIsLowerBound,
    required this.sinceLast,
    required this.historyLength,
  });

  factory of(TopicNode node, DateTime now) {
    final count = node.messageCount;
    final first = node.firstSeen;
    final last = node.last?.timestamp;
    final span = first != null && last != null ? last.difference(first) : null;
    final history = node.history.toList();
    final windowStart = now.subtract(recentWindow);
    final recent = history.where((r) => r.timestamp.isAfter(windowStart));
    // A full history whose oldest entry is inside the window may have lost
    // older messages of the window: the rate is then at least this high.
    final lowerBound =
        history.isNotEmpty &&
        history.length < count &&
        history.first.timestamp.isAfter(windowStart);
    return TopicStatistics(
      messageCount: count,
      firstSeen: first,
      lastSeen: last,
      averageSize: count == 0 ? 0 : node.totalBytes / count,
      minSize: node.minSize,
      maxSize: node.maxSize,
      overallRate: count > 1 && span != null && span.inMicroseconds > 0
          ? (count - 1) / (span.inMicroseconds / 1e6)
          : null,
      recentRate: recent.length / recentWindow.inSeconds,
      recentRateIsLowerBound: lowerBound,
      sinceLast: last == null ? null : now.difference(last),
      historyLength: history.length,
    );
  }

  /// Window of [recentRate].
  static const recentWindow = Duration(seconds: 60);

  final int messageCount;
  final DateTime? firstSeen;
  final DateTime? lastSeen;
  final double averageSize;
  final int minSize;
  final int maxSize;

  /// Messages per second between the first and the last message.
  final double? overallRate;

  /// Messages per second within the last [recentWindow].
  final double recentRate;
  final bool recentRateIsLowerBound;
  final Duration? sinceLast;
  final int historyLength;
}
