import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/files/file_exchange.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/resizable_split.dart';
import 'package:modbus_explorer/core/widgets/snackbar.dart';
import 'package:modbus_explorer/features/interpretation/domain/value_formatter.dart';
import 'package:modbus_explorer/features/modbus/data/client/frame_event.dart';
import 'package:modbus_explorer/features/modbus/domain/function_code.dart';
import 'package:modbus_explorer/features/monitor/domain/log_export.dart';
import 'package:modbus_explorer/features/monitor/presentation/communication_log_controller.dart';
import 'package:modbus_explorer/features/monitor/presentation/frame_detail.dart';
import 'package:modbus_explorer/features/monitor/presentation/frame_text.dart';

class MonitorPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends ConsumerState<MonitorPage> {
  static const _splitWidth = 1000.0;

  bool _errorsOnly = false;
  int? _functionFilter;
  FrameEvent? _selected;

  List<FrameEvent> _visible(List<FrameEvent> frames) => frames.where((f) {
    if (_errorsOnly && !frameIsError(f)) return false;
    if (_functionFilter != null &&
        frameBaseFunctionCode(f) != _functionFilter) {
      return false;
    }
    return true;
  }).toList();

  Future<void> _copy(String text, int count) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showReplacing(context.l10n.monitorCopied(count));
    }
  }

  Future<void> _save(String content, ExchangeFileType type) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final name = timestampedFileName('modbus-log', type.extension);
    try {
      final saved = await ref
          .read(fileExchangeProvider)
          .saveText(suggestedName: name, content: content, type: type);
      if (saved) messenger.showReplacing(l10n.exportSaved(name));
    } on Object catch (e) {
      messenger.showReplacing(l10n.exportFailed('$e'));
    }
  }

  void _select(FrameEvent frame, {required bool split}) {
    setState(() => _selected = frame);
    if (split) return;
    final log = ref.read(communicationLogControllerProvider);
    final sheet = showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 1,
        builder: (context, controller) => FrameDetailView(
          frame: frame,
          transaction: log.transactions[frame.transactionNumber],
          scrollController: controller,
        ),
      ),
    );
    unawaited(sheet);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final log = ref.watch(communicationLogControllerProvider);
    final controller = ref.read(communicationLogControllerProvider.notifier);
    // Newest first: on a live log the latest frames matter most.
    final visible = _visible(log.frames).reversed.toList();
    Duration? latencyOf(FrameEvent f) => f.direction == FrameDirection.rx
        ? log.transactions[f.transactionNumber]?.latency
        : null;

    final toolbar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.tonalIcon(
            key: const Key('monitor.pause'),
            onPressed: () => controller.setPaused(paused: !log.paused),
            icon: Icon(log.paused ? Icons.play_arrow : Icons.pause),
            label: Text(log.paused ? l10n.monitorResume : l10n.monitorPause),
          ),
          OutlinedButton.icon(
            key: const Key('monitor.clear'),
            onPressed: log.frames.isEmpty
                ? null
                : () {
                    controller.clear();
                    setState(() => _selected = null);
                  },
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text(l10n.monitorClear),
          ),
          FilterChip(
            key: const Key('monitor.errorsOnly'),
            label: Text(l10n.monitorErrorsOnly),
            selected: _errorsOnly,
            onSelected: (v) => setState(() => _errorsOnly = v),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<int?>(
              key: const Key('monitor.function'),
              isExpanded: true,
              initialValue: _functionFilter,
              decoration: const InputDecoration(isDense: true),
              items: [
                DropdownMenuItem(child: Text(l10n.monitorAllFunctions)),
                for (final fc in FunctionCode.values)
                  DropdownMenuItem(
                    value: fc.code,
                    child: Text('${fc.label} ${fc.name}'),
                  ),
              ],
              onChanged: (v) => setState(() => _functionFilter = v),
            ),
          ),
          PopupMenuButton<String>(
            key: const Key('monitor.export'),
            tooltip: l10n.monitorCopyText,
            icon: const Icon(Icons.ios_share),
            enabled: visible.isNotEmpty,
            onSelected: (action) {
              final ordered = visible.reversed.toList();
              final csv = action == 'copyCsv' || action == 'saveCsv';
              final content = csv
                  ? framesToCsv(ordered, latencyOf: latencyOf)
                  : ordered
                        .map((f) => frameToLine(f, latency: latencyOf(f)))
                        .join('\n');
              unawaited(
                action.startsWith('save')
                    ? _save(
                        content,
                        csv ? ExchangeFileType.csv : ExchangeFileType.text,
                      )
                    : _copy(content, ordered.length),
              );
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'copyText',
                child: ListTile(
                  leading: const Icon(Icons.notes),
                  title: Text(l10n.monitorCopyText),
                ),
              ),
              PopupMenuItem(
                value: 'copyCsv',
                child: ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: Text(l10n.monitorCopyCsv),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'saveText',
                child: ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: Text(l10n.actionSaveText),
                ),
              ),
              PopupMenuItem(
                value: 'saveCsv',
                child: ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: Text(l10n.actionSaveCsv),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final status = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        log.paused
            ? l10n.monitorPaused(log.notRecorded)
            : l10n.monitorCount(visible.length, log.frames.length),
        style: theme.textTheme.bodySmall?.copyWith(
          color: log.paused
              ? context.appColors.warning
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final split = constraints.maxWidth >= _splitWidth;
        final list = visible.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.monitorEmpty, textAlign: TextAlign.center),
                ),
              )
            : ListView.builder(
                key: const Key('monitor.list'),
                itemExtent: 52,
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final frame = visible[i];
                  return _FrameRow(
                    // Position (0 = newest); frames have no unique ID.
                    key: ValueKey('frame.$i'),
                    frame: frame,
                    latency: latencyOf(frame),
                    selected: identical(frame, _selected),
                    onTap: () => _select(frame, split: split),
                  );
                },
              );
        final selected = _selected;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            toolbar,
            status,
            const Divider(height: 1),
            Expanded(
              child: split
                  ? ResizableSplit(
                      initialFraction: 0.55,
                      minFirst: 420,
                      minSecond: 360,
                      first: list,
                      second: selected == null
                          ? Center(child: Text(l10n.monitorSelectHint))
                          : FrameDetailView(
                              frame: selected,
                              transaction:
                                  log.transactions[selected.transactionNumber],
                            ),
                    )
                  : list,
            ),
          ],
        );
      },
    );
  }
}

class _FrameRow extends StatelessWidget {
  const new({
    required this.frame,
    required this.latency,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final FrameEvent frame;
  final Duration? latency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final mono = theme.textTheme.bodySmall!.mono;
    final isTx = frame.direction == FrameDirection.tx;
    final isError = frameIsError(frame);
    final status = frame.status == FrameStatus.ok && isError
        ? l10n.frameStatusException
        : frameStatusLabel(l10n, frame.status);

    return Material(
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(formatLogTime(frame.timestamp), style: mono),
              ),
              Container(
                width: 34,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: (isTx ? colors.tx : colors.rx).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isTx ? 'TX' : 'RX',
                  style: mono.copyWith(
                    color: isTx ? colors.tx : colors.rx,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(frameFunctionLabel(frame), style: mono),
              ),
              Expanded(
                child: Text(
                  formatHexBytes(frame.bytes),
                  style: mono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (latency != null)
                Text('${latency!.inMilliseconds} ms', style: mono),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: Text(
                  status,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isError ? theme.colorScheme.error : colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
