import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_filter.dart';

/// One level of the topic hierarchy. A node is a *topic* once a message was
/// received on exactly its path; intermediate levels only aggregate.
///
/// Mutable on purpose: the tree is updated in place for every message
/// (O(depth)) and the UI takes cheap snapshots via [TopicTree.visibleRows].
final class TopicNode {
  new _(this.name, this.path, this.parent)
    : depth = parent == null ? -1 : parent.depth + 1;

  /// Level name; can be empty (`a//b`, `/a`).
  final String name;

  /// Full topic, levels joined by `/`. Empty for the root.
  final String path;
  final TopicNode? parent;

  /// 0 for the first level; the invisible root is -1.
  final int depth;

  final Map<String, TopicNode> _children = HashMap();
  List<TopicNode>? _sortedChildren;

  /// Last message on exactly this topic.
  MqttMessageRecord? last;

  /// Messages on exactly this topic.
  int messageCount = 0;

  /// Messages on this topic and all below it.
  int totalMessages = 0;

  /// Topics (nodes with messages) strictly below this node.
  int descendantTopics = 0;

  /// Time of the latest message in this subtree.
  DateTime? lastActivity;

  /// When [last]'s payload differed from the message before it.
  DateTime? lastChangedAt;

  /// Increases whenever the payload of this topic changes (UI highlight).
  int changeVersion = 0;

  /// Whether the payload ever changed (more than one distinct value).
  bool hasChanged = false;

  /// First message on this topic.
  DateTime? firstSeen;

  /// Payload bytes of all messages on this topic (also evicted ones).
  int totalBytes = 0;
  int minSize = 0;
  int maxSize = 0;

  final ListQueue<HistoryEntry> _history = ListQueue();

  /// Recent messages on this topic, oldest first; bounded by
  /// [TopicTree.historyPerTopic] and the tree's memory budget.
  Iterable<MqttMessageRecord> get history => _history.map((e) => e.record);
  int get historyLength => _history.length;

  bool get isTopic => messageCount > 0;
  bool get hasChildren => _children.isNotEmpty;
  int get childCount => _children.length;

  /// Children sorted by name (case-insensitive, numbers numerically);
  /// cached until a child is added.
  List<TopicNode> get children =>
      _sortedChildren ??= _children.values.toList()
        ..sort((a, b) => compareTopicLevels(a.name, b.name));

  TopicNode? child(String name) => _children[name];

  /// Whether any topic in this subtree changed its value.
  bool get subtreeHasChanged =>
      hasChanged || children.any((c) => c.subtreeHasChanged);
}

final _chunks = RegExp(r'\d+|\D+');

/// Natural order: `sensor2` before `sensor10`, case-insensitive.
int compareTopicLevels(String a, String b) {
  final digits = _chunks;
  final pa = digits.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
  final pb = digits.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final na = int.tryParse(pa[i]);
    final nb = int.tryParse(pb[i]);
    final c = na != null && nb != null
        ? na.compareTo(nb)
        : pa[i].compareTo(pb[i]);
    if (c != 0) return c;
  }
  final byLength = pa.length.compareTo(pb.length);
  return byLength != 0 ? byLength : a.compareTo(b);
}

enum TopicFilterMode { text, wildcard, regex }

/// What the tree shows. An invalid regex shows nothing and sets
/// [TopicTreeQuery.error].
@immutable
final class TopicTreeQuery {
  const new({
    this.text = '',
    this.mode = TopicFilterMode.text,
    this.showSys = true,
    this.onlyChanged = false,
  });

  final String text;
  final TopicFilterMode mode;

  /// Show `$SYS/…` (and other `$` topics).
  final bool showSys;

  /// Hide topics whose payload never changed.
  final bool onlyChanged;

  bool get isFiltering => text.trim().isNotEmpty || onlyChanged;

  /// Error of an invalid filter (regex syntax, invalid wildcard filter).
  String? get error {
    final t = text.trim();
    if (t.isEmpty) return null;
    switch (mode) {
      case TopicFilterMode.regex:
        try {
          RegExp(t);
          return null;
        } on FormatException catch (e) {
          return e.message;
        }
      case TopicFilterMode.wildcard:
        return validateTopicFilter(t)?.name;
      case TopicFilterMode.text:
        return null;
    }
  }

  /// Predicate on topic paths; `null` = everything matches.
  bool Function(String path)? matcher() {
    final t = text.trim();
    if (t.isEmpty || error != null) {
      return t.isEmpty ? null : (_) => false;
    }
    switch (mode) {
      case TopicFilterMode.text:
        final needle = t.toLowerCase();
        return (path) => path.toLowerCase().contains(needle);
      case TopicFilterMode.wildcard:
        return (path) => topicMatches(t, path);
      case TopicFilterMode.regex:
        final re = RegExp(t, caseSensitive: false);
        return re.hasMatch;
    }
  }

  TopicTreeQuery copyWith({
    String? text,
    TopicFilterMode? mode,
    bool? showSys,
    bool? onlyChanged,
  }) => TopicTreeQuery(
    text: text ?? this.text,
    mode: mode ?? this.mode,
    showSys: showSys ?? this.showSys,
    onlyChanged: onlyChanged ?? this.onlyChanged,
  );

  @override
  bool operator ==(Object other) =>
      other is TopicTreeQuery &&
      other.text == text &&
      other.mode == mode &&
      other.showSys == showSys &&
      other.onlyChanged == onlyChanged;

  @override
  int get hashCode => Object.hash(text, mode, showSys, onlyChanged);
}

/// A visible line of the flattened tree.
@immutable
final class TopicRow {
  const new({
    required this.node,
    required this.expanded,
    required this.forcedOpen,
  });

  final TopicNode node;
  final bool expanded;

  /// Opened by a filter, not by the user (collapsing has no effect).
  final bool forcedOpen;
}

/// Live tree of all received topics.
/// A history slot; [seq] orders all entries of the tree globally.
@immutable
final class HistoryEntry {
  const new(this.seq, this.record, this.size);

  final int seq;
  final MqttMessageRecord record;

  /// Bytes counted against the budget (payload + fixed overhead).
  final int size;
}

final class TopicTree {
  new({this.historyPerTopic = 100, this.historyBudgetBytes = 64 << 20});

  /// Estimated bookkeeping per stored message besides the payload.
  static const entryOverhead = 96;

  /// Messages kept per topic.
  int historyPerTopic;

  /// Upper bound for all histories together; the globally oldest entries
  /// go first, so busy topics cannot starve quiet ones of their last value
  /// ([TopicNode.last] is always kept).
  int historyBudgetBytes;

  int _seq = 0;
  int _historyBytes = 0;
  int _historyCount = 0;

  /// Global insertion order for budget eviction. Entries already dropped by
  /// the per-topic limit stay until they reach the head (or a compaction).
  final ListQueue<(TopicNode, int, int)> _evictionQueue = ListQueue();

  /// Memory used by all histories (estimate).
  int get historyBytes => _historyBytes;

  /// Messages in all histories.
  int get historyCount => _historyCount;

  final TopicNode root = TopicNode._('', '', null);

  /// Number of distinct topics with at least one message.
  int get topicCount => root.descendantTopics;

  /// All messages added since the last [clear].
  int get messageCount => root.totalMessages;

  /// Adds a received message. Returns the topic's node.
  TopicNode add(MqttMessageRecord record) {
    final levels = record.topic.split('/');
    final path = <TopicNode>[root];
    var node = root;
    for (var i = 0; i < levels.length; i++) {
      final name = levels[i];
      var next = node._children[name];
      if (next == null) {
        next = TopicNode._(name, i == 0 ? name : '${node.path}/$name', node);
        node._children[name] = next;
        node._sortedChildren = null;
      }
      node = next;
      path.add(node);
    }

    final firstMessage = node.messageCount == 0;
    final previous = node.last;
    if (previous != null && !_samePayload(previous, record)) {
      node
        ..hasChanged = true
        ..lastChangedAt = record.timestamp
        ..changeVersion += 1;
    } else if (previous == null) {
      node
        ..lastChangedAt = record.timestamp
        ..changeVersion += 1;
    }
    final size = record.payload.length;
    node
      ..last = record
      ..messageCount += 1
      ..firstSeen ??= record.timestamp
      ..totalBytes += size
      ..minSize = node.messageCount == 1
          ? size
          : (size < node.minSize ? size : node.minSize)
      ..maxSize = size > node.maxSize ? size : node.maxSize;
    _remember(node, record);
    for (final n in path) {
      n
        ..totalMessages += 1
        ..lastActivity = record.timestamp;
      if (firstMessage && n != node) n.descendantTopics += 1;
    }
    return node;
  }

  void _remember(TopicNode node, MqttMessageRecord record) {
    final entry = HistoryEntry(
      _seq++,
      record,
      record.payload.length + entryOverhead,
    );
    node._history.add(entry);
    _historyBytes += entry.size;
    _historyCount++;
    _evictionQueue.add((node, entry.seq, entry.size));
    _trimTopic(node);
    _enforceBudget();
  }

  void _trimTopic(TopicNode node) {
    while (node._history.length > historyPerTopic) {
      final dropped = node._history.removeFirst();
      _historyBytes -= dropped.size;
      _historyCount--;
    }
  }

  void _enforceBudget() {
    while (_historyBytes > historyBudgetBytes && _evictionQueue.isNotEmpty) {
      final (node, seq, size) = _evictionQueue.removeFirst();
      // Per-topic trimming removes from the front too, so a queue entry is
      // live exactly when it is still the topic's oldest entry.
      if (node._history.isNotEmpty && node._history.first.seq == seq) {
        node._history.removeFirst();
        _historyBytes -= size;
        _historyCount--;
      }
    }
    // Drop stale queue entries before they outgrow the live ones.
    if (_evictionQueue.length > 2 * _historyCount + 1024) {
      final live = _evictionQueue.where(
        (e) => e.$1._history.isNotEmpty && e.$2 >= e.$1._history.first.seq,
      );
      final compacted = ListQueue<(TopicNode, int, int)>.of(live);
      _evictionQueue
        ..clear()
        ..addAll(compacted);
    }
  }

  /// Applies new limits to the existing histories.
  void setHistoryLimits({required int perTopic, required int budgetBytes}) {
    historyPerTopic = perTopic;
    historyBudgetBytes = budgetBytes;
    void visit(TopicNode node) {
      _trimTopic(node);
      node._children.values.forEach(visit);
    }

    visit(root);
    _enforceBudget();
  }

  static bool _samePayload(MqttMessageRecord a, MqttMessageRecord b) {
    final x = a.payload;
    final y = b.payload;
    if (x.length != y.length) return false;
    for (var i = 0; i < x.length; i++) {
      if (x[i] != y[i]) return false;
    }
    return true;
  }

  TopicNode? find(String path) {
    var node = root;
    for (final level in path.split('/')) {
      final next = node._children[level];
      if (next == null) return null;
      node = next;
    }
    return node;
  }

  void clear() {
    _evictionQueue.clear();
    _historyBytes = 0;
    _historyCount = 0;
    root
      .._children.clear()
      .._sortedChildren = null
      ..totalMessages = 0
      ..descendantTopics = 0
      ..lastActivity = null;
  }

  /// Depth-first list of the lines to show. Without a filter, children of
  /// [expanded] paths are visible. With a filter, only matching topics and
  /// their ancestors are shown, ancestors opened automatically.
  List<TopicRow> visibleRows({
    required Set<String> expanded,
    TopicTreeQuery query = const TopicTreeQuery(),
  }) {
    final rows = <TopicRow>[];
    final matcher = query.matcher();
    final filtering = matcher != null || query.onlyChanged;

    bool matches(TopicNode n) =>
        n.isTopic &&
        (matcher == null || matcher(n.path)) &&
        (!query.onlyChanged || n.hasChanged);

    // Memo for "subtree contains a match" so filtering stays O(nodes).
    final containsMatch = HashMap<TopicNode, bool>.identity();
    bool subtreeMatches(TopicNode n) =>
        containsMatch[n] ??= matches(n) || n.children.any(subtreeMatches);

    void visit(TopicNode node) {
      for (final child in node.children) {
        if (!query.showSys && child.depth == 0 && child.name.startsWith(r'$')) {
          continue;
        }
        if (filtering && !subtreeMatches(child)) continue;
        final userOpen = expanded.contains(child.path);
        // A filter opens ancestors of matches so they are visible.
        final forced =
            filtering && child.children.any(subtreeMatches) && !userOpen;
        final open = child.hasChildren && (userOpen || forced);
        rows.add(TopicRow(node: child, expanded: open, forcedOpen: forced));
        if (open) visit(child);
      }
    }

    visit(root);
    return rows;
  }

  /// Paths of all nodes with children (for "expand all").
  Set<String> allBranchPaths() {
    final result = <String>{};
    void visit(TopicNode node) {
      for (final child in node._children.values) {
        if (child.hasChildren) {
          result.add(child.path);
          visit(child);
        }
      }
    }

    visit(root);
    return result;
  }
}
