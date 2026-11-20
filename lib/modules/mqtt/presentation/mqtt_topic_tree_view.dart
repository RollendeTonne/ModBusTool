import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_codec.dart';
import 'package:modbus_explorer/modules/mqtt/domain/topic_tree.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topic_tree_controller.dart';

/// Toolbar (filter, toggles) above the virtualized topic tree.
class MqttTopicTreeView extends ConsumerStatefulWidget {
  const new({this.onSelected, super.key});

  /// Called after a topic (a node with messages) was selected; phones
  /// switch to the details.
  final ValueChanged<String>? onSelected;

  static const rowHeight = 40.0;

  @override
  ConsumerState<MqttTopicTreeView> createState() => _MqttTopicTreeViewState();
}

class _MqttTopicTreeViewState extends ConsumerState<MqttTopicTreeView> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(topicTreeViewControllerProvider).query.text;
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  TopicTreeViewController get _view =>
      ref.read(topicTreeViewControllerProvider.notifier);

  void _setQuery(TopicTreeQuery Function(TopicTreeQuery q) change) =>
      _view.setQuery(change(ref.read(topicTreeViewControllerProvider).query));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final snapshot = ref.watch(mqttTopicTreeControllerProvider);
    final view = ref.watch(topicTreeViewControllerProvider);
    final rows = ref.watch(visibleTopicRowsProvider);
    final query = view.query;
    final error = query.error;
    final shortcut = defaultTargetPlatform == TargetPlatform.macOS
        ? '⌘F'
        : 'Ctrl+F';
    void focusSearch() => _searchFocus.requestFocus();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): focusSearch,
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Tooltip(
                    message: l10n.mqttTreeSearchTooltip(shortcut),
                    child: TextField(
                      key: const Key('mqtt.tree.search'),
                      controller: _search,
                      focusNode: _searchFocus,
                      style: theme.textTheme.bodyMedium!.mono,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        labelText: l10n.mqttTreeSearch,
                        errorText: error == null
                            ? null
                            : l10n.mqttTreeFilterError(error),
                        errorMaxLines: 2,
                        suffixIcon: query.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: l10n.mqttClear,
                                onPressed: () {
                                  _search.clear();
                                  _setQuery((q) => q.copyWith(text: ''));
                                },
                              ),
                      ),
                      onChanged: (text) =>
                          _setQuery((q) => q.copyWith(text: text)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<TopicFilterMode>(
                  key: const Key('mqtt.tree.mode'),
                  value: query.mode,
                  items: [
                    DropdownMenuItem(
                      value: TopicFilterMode.text,
                      child: Text(l10n.mqttFilterText),
                    ),
                    DropdownMenuItem(
                      value: TopicFilterMode.wildcard,
                      child: Text(l10n.mqttFilterWildcard),
                    ),
                    DropdownMenuItem(
                      value: TopicFilterMode.regex,
                      child: Text(l10n.mqttFilterRegex),
                    ),
                  ],
                  onChanged: (m) => _setQuery((q) => q.copyWith(mode: m)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          key: const Key('mqtt.tree.sys'),
                          label: Text(l10n.mqttTreeShowSys),
                          selected: query.showSys,
                          onSelected: (v) =>
                              _setQuery((q) => q.copyWith(showSys: v)),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: l10n.mqttTreeOnlyChangedTooltip,
                          child: FilterChip(
                            key: const Key('mqtt.tree.onlyChanged'),
                            label: Text(l10n.mqttTreeOnlyChanged),
                            selected: query.onlyChanged,
                            onSelected: (v) =>
                                _setQuery((q) => q.copyWith(onlyChanged: v)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('mqtt.tree.expandAll'),
                  tooltip: l10n.mqttTreeExpandAll,
                  icon: const Icon(Icons.unfold_more),
                  onPressed: _view.expandAll,
                ),
                IconButton(
                  key: const Key('mqtt.tree.collapseAll'),
                  tooltip: l10n.mqttTreeCollapseAll,
                  icon: const Icon(Icons.unfold_less),
                  onPressed: _view.collapseAll,
                ),
                IconButton(
                  key: const Key('mqtt.tree.clear'),
                  tooltip: l10n.mqttTreeClear,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () {
                    ref.read(mqttTopicTreeControllerProvider.notifier).clear();
                    _view.select(null);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.mqttTreeStats(snapshot.topicCount, snapshot.messageCount),
                key: const Key('mqtt.tree.stats'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        snapshot.topicCount == 0
                            ? l10n.mqttTreeEmpty
                            : l10n.mqttTreeNoMatch,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    key: const Key('mqtt.tree.list'),
                    itemCount: rows.length,
                    itemExtent: MqttTopicTreeView.rowHeight,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      final path = row.node.path;
                      return TopicTreeRow(
                        key: ValueKey(path),
                        row: row,
                        selected: view.selected == path,
                        onToggle: () => _view.toggle(path),
                        onSelect: () {
                          _view.select(path);
                          if (!row.node.isTopic &&
                              row.node.hasChildren &&
                              !row.forcedOpen) {
                            _view.toggle(path);
                          }
                          // Pure branches only expand; jumping to the
                          // details (phones) is for actual topics.
                          if (row.node.isTopic) widget.onSelected?.call(path);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One line: indentation, chevron, level name, last value, badges. A new
/// value flashes the line ([TopicNode.changeVersion]).
class TopicTreeRow extends StatelessWidget {
  const new({
    required this.row,
    required this.selected,
    required this.onToggle,
    required this.onSelect,
    super.key,
  });

  final TopicRow row;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onSelect;

  static const highlightDuration = Duration(milliseconds: 1500);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final node = row.node;
    final last = node.last;
    final mono = theme.textTheme.bodyMedium!.mono;
    final name = node.name.isEmpty ? l10n.mqttEmptyLevel : node.name;

    final content = Row(
      children: [
        SizedBox(width: 8.0 + node.depth * 16),
        if (node.hasChildren)
          IconButton(
            key: Key('mqtt.tree.toggle.${node.path}'),
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            tooltip: row.expanded ? l10n.mqttCollapse : l10n.mqttExpand,
            icon: Icon(row.expanded ? Icons.expand_more : Icons.chevron_right),
            onPressed: row.forcedOpen ? null : onToggle,
          )
        else
          const SizedBox(width: 40),
        // Name and value share the space; badges stay at the right edge.
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mono.copyWith(
                    fontWeight: node.isTopic ? FontWeight.w600 : null,
                    fontStyle: node.name.isEmpty ? FontStyle.italic : null,
                  ),
                ),
              ),
              if (last != null) ...[
                Text(
                  ' = ',
                  style: mono.copyWith(color: scheme.onSurfaceVariant),
                ),
                Flexible(
                  child: Text(
                    payloadPreview(last.payload, maxChars: 80),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: mono.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (last?.retain ?? false)
          Tooltip(
            message: l10n.mqttRetainedBadge,
            child: Icon(
              Icons.push_pin_outlined,
              size: 16,
              color: scheme.tertiary,
            ),
          ),
        const SizedBox(width: 6),
        _Badge(
          text: node.hasChildren
              ? l10n.mqttNodeTopics(node.descendantTopics)
              : l10n.mqttNodeMessages(node.messageCount),
        ),
        const SizedBox(width: 8),
      ],
    );

    final tile = InkWell(
      key: Key('mqtt.tree.row.${node.path}'),
      onTap: onSelect,
      child: content,
    );
    Color background(double flash) => selected
        ? scheme.secondaryContainer
        : Color.lerp(Colors.transparent, scheme.primaryContainer, flash)!;

    // With "reduce motion" the change is marked statically for the
    // highlight period instead of fading.
    if (MediaQuery.disableAnimationsOf(context)) {
      final changed = node.lastChangedAt;
      final recent =
          node.isTopic &&
          changed != null &&
          DateTime.now().difference(changed) < highlightDuration;
      return Semantics(
        selected: selected,
        button: true,
        child: Material(color: background(recent ? 0.6 : 0), child: tile),
      );
    }
    return Semantics(
      selected: selected,
      button: true,
      child: TweenAnimationBuilder<double>(
        // Restarts the fade whenever the topic's value changes.
        key: ValueKey(node.changeVersion),
        tween: Tween(begin: node.isTopic ? 1 : 0, end: 0),
        duration: highlightDuration,
        builder: (context, flash, child) =>
            Material(color: background(flash), child: child),
        child: tile,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
    );
  }
}
