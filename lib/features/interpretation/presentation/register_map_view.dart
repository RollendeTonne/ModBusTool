import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/error_panel.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/features/connection/presentation/connection_controller.dart';
import 'package:modbus_explorer/features/connection/presentation/modbus_error_text.dart';
import 'package:modbus_explorer/features/interpretation/domain/byte_order.dart';
import 'package:modbus_explorer/features/interpretation/domain/data_type.dart';
import 'package:modbus_explorer/features/interpretation/domain/plausibility.dart';
import 'package:modbus_explorer/features/interpretation/domain/register_map_entry.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/interpretation/presentation/map_entry_dialog.dart';
import 'package:modbus_explorer/features/interpretation/presentation/map_values_controller.dart';
import 'package:modbus_explorer/features/interpretation/presentation/register_map_controller.dart';
import 'package:modbus_explorer/features/interpretation/presentation/value_format_text.dart';
import 'package:modbus_explorer/features/modbus/domain/addressing_mode.dart';
import 'package:modbus_explorer/features/modbus/domain/modbus_address.dart';
import 'package:modbus_explorer/features/registers/presentation/register_table.dart';
import 'package:modbus_explorer/features/registers/presentation/registers_controller.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_controller.dart';

enum _SortOrder { address, label }

/// The register map of the current profile with live values.
class RegisterMapSliver extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<RegisterMapSliver> createState() => _RegisterMapSliverState();
}

class _RegisterMapSliverState extends ConsumerState<RegisterMapSliver> {
  final _search = TextEditingController();
  _SortOrder _sort = _SortOrder.address;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<RegisterMapEntry> _filtered(
    List<RegisterMapEntry> entries,
    AddressingMode mode,
  ) {
    final query = _search.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? [...entries]
        : entries.where((e) {
            final address = ModbusAddress.format(e.address, e.table, mode);
            return e.label.toLowerCase().contains(query) ||
                e.description.toLowerCase().contains(query) ||
                address.contains(query) ||
                '${e.address}' == query;
          }).toList();
    if (_sort == _SortOrder.label) {
      filtered.sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
    }
    return filtered;
  }

  Future<void> _addEntry() async {
    final query = ref.read(registersControllerProvider).query;
    final entry = await showMapEntryDialog(
      context,
      isNew: true,
      initial: RegisterMapEntry(
        id: RegisterMapController.newEntryId(),
        table: query.table,
        address: query.address,
        format: query.table.isBitTable
            ? BitFormat()
            : NumericFormat(DataType.uint16, ByteOrder.parse('AB')),
      ),
    );
    if (entry != null && mounted) {
      final saved = await saveMapEntry(ref, entry);
      if (!saved && mounted) {
        ScaffoldMessenger.of(context).showReplacing(context.l10n.mapNoProfile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profileId = ref.watch(currentProfileIdProvider);
    final entries = ref.watch(currentMapEntriesProvider);
    final values = ref.watch(mapValuesControllerProvider);
    final controller = ref.read(mapValuesControllerProvider.notifier);
    final mode = ref.watch(
      settingsControllerProvider.select((s) => s.addressingMode),
    );
    final connected = ref.watch(activeClientProvider) != null;
    final visible = _filtered(entries, mode);
    final time = DateFormat.Hms(Localizations.localeOf(context).toString());
    final error = values.lastError;

    final toolbar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              key: const Key('map.search'),
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.mapSearch,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SegmentedButton<_SortOrder>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _SortOrder.address,
                label: Text(l10n.mapSortAddress),
              ),
              ButtonSegment(
                value: _SortOrder.label,
                label: Text(l10n.mapSortLabel),
              ),
            ],
            selected: {_sort},
            onSelectionChanged: (s) => setState(() => _sort = s.single),
          ),
          FilledButton.icon(
            key: const Key('map.read'),
            onPressed: connected && entries.isNotEmpty && !values.isPolling
                ? controller.read
                : null,
            icon: const Icon(Icons.download),
            label: Text(l10n.actionReadMap),
          ),
          FilledButton.tonalIcon(
            key: const Key('map.poll'),
            onPressed: connected && entries.isNotEmpty || values.isPolling
                ? controller.togglePolling
                : null,
            icon: Icon(values.isPolling ? Icons.stop : Icons.play_arrow),
            label: Text(
              values.isPolling
                  ? l10n.actionStopPolling
                  : l10n.actionStartPolling,
            ),
          ),
          OutlinedButton.icon(
            key: const Key('map.add'),
            onPressed: profileId == null ? null : _addEntry,
            icon: const Icon(Icons.add),
            label: Text(l10n.actionAddEntry),
          ),
        ],
      ),
    );

    final status = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        values.readAt == null
            ? l10n.mapEntryCount(entries.length)
            : l10n.mapReadStatus(entries.length, time.format(values.readAt!)),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: toolbar),
        if (error != null && error is! NotConnectedError)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Builder(
                builder: (context) {
                  final text = describeError(l10n, error);
                  return ErrorPanel(
                    title: text.title,
                    hint: text.hint,
                    detail: text.detail,
                    dense: true,
                  );
                },
              ),
            ),
          ),
        SliverToBoxAdapter(child: status),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        if (entries.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                profileId == null ? l10n.mapNoProfile : l10n.mapEmpty,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverList.separated(
            itemCount: visible.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final entry = visible[i];
              return _MapEntryTile(
                key: ValueKey('map.entry.${entry.id}'),
                entry: entry,
                displayAddress: ModbusAddress.format(
                  entry.address,
                  entry.table,
                  mode,
                ),
                value: values.values[entry.id],
                error: values.errors[entry.id],
              );
            },
          ),
      ],
    );
  }
}

enum _EntryAction { edit, delete }

class _MapEntryTile extends ConsumerWidget {
  const new({
    required this.entry,
    required this.displayAddress,
    required this.value,
    required this.error,
    super.key,
  });

  final RegisterMapEntry entry;
  final String displayAddress;
  final MapValue? value;
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final mono = theme.textTheme.bodyMedium!.mono;
    final current = value;
    final assessment = current == null
        ? null
        : assessPlausibility(
            current.value,
            entry.format is NumericFormat
                ? (entry.format as NumericFormat).type
                : DataType.uint16,
          );
    final implausible = assessment?.level == Plausibility.implausible;

    final String valueText;
    if (error != null) {
      valueText = describeError(l10n, error!).title;
    } else if (current == null) {
      valueText = ValueFormatter.invalidPlaceholder;
    } else {
      final formatted = ValueFormatter.format(
        current.value,
        scaling: entry.scaling,
      );
      valueText = entry.unit.isEmpty ? formatted : '$formatted ${entry.unit}';
    }

    final changedAt = current?.changedAt;
    final recentlyChanged =
        changedAt != null &&
        DateTime.now().difference(changedAt) < changeHighlightDuration;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: recentlyChanged ? colors.changed.withValues(alpha: 0.5) : null,
      child: ListTile(
        title: Text(entry.label.isEmpty ? l10n.mapUnnamed : entry.label),
        subtitle: Text(
          [
            '$displayAddress · ${describeFormat(entry.format)}',
            if (entry.description.isNotEmpty) entry.description,
          ].join('\n'),
          style: theme.textTheme.bodySmall!.mono,
        ),
        isThreeLine: entry.description.isNotEmpty,
        onTap: () => _edit(context, ref),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                valueText,
                key: Key('map.value.${entry.id}'),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: mono.copyWith(
                  fontSize: theme.textTheme.titleMedium!.fontSize,
                  fontWeight: FontWeight.w600,
                  color: error != null
                      ? theme.colorScheme.error
                      : implausible
                      ? colors.implausible
                      : null,
                  fontStyle: implausible ? FontStyle.italic : null,
                ),
              ),
            ),
            PopupMenuButton<_EntryAction>(
              onSelected: (action) => switch (action) {
                _EntryAction.edit => _edit(context, ref),
                _EntryAction.delete => _delete(context, ref),
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _EntryAction.edit,
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.actionEdit),
                  ),
                ),
                PopupMenuItem(
                  value: _EntryAction.delete,
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(l10n.actionDelete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final updated = await showMapEntryDialog(
      context,
      initial: entry,
      isNew: false,
    );
    if (updated != null) await saveMapEntry(ref, updated);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mapEntryDeleteTitle),
        content: Text(
          l10n.mapEntryDeleteBody(
            entry.label.isEmpty ? l10n.mapUnnamed : entry.label,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      unawaited(
        ref
            .read(registerMapControllerProvider.notifier)
            .deleteEntry(profileId, entry.id),
      );
    }
  }
}
