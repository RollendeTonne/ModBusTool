import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_history_settings.dart';

/// Version stamp of the live tree; the tree itself is mutated in place.
@immutable
final class TopicTreeSnapshot {
  const new({
    required this.tree,
    required this.version,
    required this.topicCount,
    required this.messageCount,
  });

  final TopicTree tree;
  final int version;
  final int topicCount;
  final int messageCount;

  @override
  bool operator ==(Object other) =>
      other is TopicTreeSnapshot && other.version == version;

  @override
  int get hashCode => version.hashCode;
}

/// Feeds received messages into the [TopicTree]. Inserting is O(depth)
/// and done immediately; the UI is notified at most every [flushInterval]
/// so a high message rate costs one rebuild per interval.
final class MqttTopicTreeController extends Notifier<TopicTreeSnapshot> {
  static const flushInterval = Duration(milliseconds: 200);

  final _tree = TopicTree();
  Timer? _flush;
  int _version = 0;
  String? _profileId;

  @override
  TopicTreeSnapshot build() {
    final limits = ref.read(mqttHistorySettingsProvider);
    _tree.setHistoryLimits(
      perTopic: limits.perTopic,
      budgetBytes: limits.budgetBytes,
    );
    ref.listen(mqttHistorySettingsProvider, (_, next) {
      _tree.setHistoryLimits(
        perTopic: next.perTopic,
        budgetBytes: next.budgetBytes,
      );
      _version++;
      state = _snapshot();
    });
    final connection = ref.watch(mqttConnectionControllerProvider.notifier);
    final subscription = connection.traffic.listen(_onMessage);
    // A different broker starts with an empty tree.
    ref
      ..listen(mqttConnectionControllerProvider, (previous, next) {
        final id = next.profile?.id;
        if (next.status == MqttConnectionStatus.connecting &&
            id != null &&
            id != _profileId) {
          _profileId = id;
          clear();
        }
      })
      ..onDispose(() {
        unawaited(subscription.cancel());
        _flush?.cancel();
      });
    return _snapshot();
  }

  TopicTreeSnapshot _snapshot() => TopicTreeSnapshot(
    tree: _tree,
    version: _version,
    topicCount: _tree.topicCount,
    messageCount: _tree.messageCount,
  );

  void _onMessage(MqttMessageRecord record) {
    // The tree shows what the broker delivers; own publishes appear when
    // they come back through a subscription.
    if (record.direction != MqttDirection.received) return;
    _tree.add(record);
    _flush ??= Timer(flushInterval, _publish);
  }

  void _publish() {
    _flush = null;
    _version++;
    state = _snapshot();
  }

  void clear() {
    _flush?.cancel();
    _flush = null;
    _tree.clear();
    _version++;
    state = _snapshot();
  }
}

final mqttTopicTreeControllerProvider =
    NotifierProvider<MqttTopicTreeController, TopicTreeSnapshot>(
      MqttTopicTreeController.new,
    );

@immutable
final class TopicTreeViewState {
  const new({
    this.expanded = const {},
    this.selected,
    this.query = const TopicTreeQuery(),
  });

  final Set<String> expanded;
  final String? selected;
  final TopicTreeQuery query;

  TopicTreeViewState copyWith({
    Set<String>? expanded,
    String? Function()? selected,
    TopicTreeQuery? query,
  }) => TopicTreeViewState(
    expanded: expanded ?? this.expanded,
    selected: selected != null ? selected() : this.selected,
    query: query ?? this.query,
  );
}

/// Expansion, selection and filter of the tree view.
final class TopicTreeViewController extends Notifier<TopicTreeViewState> {
  @override
  TopicTreeViewState build() => const TopicTreeViewState();

  void toggle(String path) {
    final expanded = {...state.expanded};
    if (!expanded.remove(path)) expanded.add(path);
    state = state.copyWith(expanded: expanded);
  }

  void expandAll() => state = state.copyWith(
    expanded: ref.read(mqttTopicTreeControllerProvider).tree.allBranchPaths(),
  );

  void collapseAll() => state = state.copyWith(expanded: const {});

  void select(String? path) => state = state.copyWith(selected: () => path);

  void setQuery(TopicTreeQuery query) => state = state.copyWith(query: query);
}

final topicTreeViewControllerProvider =
    NotifierProvider<TopicTreeViewController, TopicTreeViewState>(
      TopicTreeViewController.new,
    );

/// Flattened visible rows; recomputed when the tree publishes a new
/// version or the view state changes.
final visibleTopicRowsProvider = Provider<List<TopicRow>>((ref) {
  final snapshot = ref.watch(mqttTopicTreeControllerProvider);
  final view = ref.watch(topicTreeViewControllerProvider);
  return snapshot.tree.visibleRows(expanded: view.expanded, query: view.query);
});
