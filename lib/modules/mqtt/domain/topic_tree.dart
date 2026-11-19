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
final class TopicTree {
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
    node
      ..last = record
      ..messageCount += 1;
    for (final n in path) {
      n
        ..totalMessages += 1
        ..lastActivity = record.timestamp;
      if (firstMessage && n != node) n.descendantTopics += 1;
    }
    return node;
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
