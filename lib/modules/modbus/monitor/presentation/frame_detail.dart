import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/core/widgets/error_panel.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/modbus_error_text.dart';
import 'package:modbus_explorer/modules/modbus/monitor/domain/log_export.dart';
import 'package:modbus_explorer/modules/modbus/monitor/presentation/frame_text.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/frame_event.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/client/modbus_transaction.dart';
import 'package:modbus_explorer/modules/modbus/protocol/data/codec/frame_dissector.dart';

/// Hex dump with colour-coded fields, field table and transaction result.
class FrameDetailView extends StatelessWidget {
  const new({
    required this.frame,
    this.transaction,
    this.scrollController,
    super.key,
  });

  final FrameEvent frame;
  final ModbusTransaction? transaction;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium!.mono;
    final dissection = dissectFrame(
      frame.bytes,
      frame.kind,
      isRequest: frame.isRequest,
    );
    final palette = [
      theme.colorScheme.primaryContainer,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.tertiaryContainer,
      theme.colorScheme.surfaceContainerHighest,
    ];
    Color colorOf(int index, FrameSegment segment) => segment.isValid
        ? palette[index % palette.length]
        : theme.colorScheme.errorContainer;

    // Byte index → segment index, for colouring the dump.
    final owner = List<int?>.filled(frame.bytes.length, null);
    for (final (i, s) in dissection.segments.indexed) {
      for (var b = s.offset; b < s.offset + s.length && b < owner.length; b++) {
        owner[b] = i;
      }
    }
    final crcValid = dissection.crcValid;
    final t = transaction;
    final error = t?.error;

    return ListView(
      key: const Key('monitor.detail'),
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      children: [
        Text(l10n.monitorDetailTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          '${formatLogTime(frame.timestamp)} · '
          '${frame.direction.name.toUpperCase()} · '
          '${frame.kind.name.toUpperCase()} · ${frame.bytes.length} B · '
          '${frameStatusLabel(l10n, frame.status)}',
          style: theme.textTheme.bodySmall!.mono,
        ),
        if (crcValid != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                crcValid ? Icons.verified_outlined : Icons.error_outline,
                size: 18,
                color: crcValid
                    ? context.appColors.success
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(crcValid ? l10n.monitorCrcValid : l10n.monitorCrcInvalid),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.monitorHexDump, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            for (var i = 0; i < frame.bytes.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: owner[i] == null
                      ? null
                      : colorOf(owner[i]!, dissection.segments[owner[i]!]),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  frame.bytes[i]
                      .toRadixString(16)
                      .toUpperCase()
                      .padLeft(2, '0'),
                  style: mono,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.monitorFields, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Table(
          key: const Key('monitor.fields'),
          columnWidths: const {
            0: FixedColumnWidth(18),
            1: IntrinsicColumnWidth(),
            2: FixedColumnWidth(64),
            3: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            for (final (i, s) in dissection.segments.indexed)
              TableRow(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorOf(i, s),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      segmentLabel(l10n, s.kind),
                      style: TextStyle(
                        color: s.isValid ? null : theme.colorScheme.error,
                        fontWeight: s.isValid ? null : FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    s.length <= 1
                        ? '${s.offset}'
                        : '${s.offset}–${s.offset + s.length - 1}',
                    style: theme.textTheme.bodySmall!.mono.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SelectableText(s.display, style: mono),
                ],
              ),
          ],
        ),
        if (t != null) ...[
          const SizedBox(height: 16),
          Text(
            l10n.monitorTransaction(t.number),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            [
              'Unit ${t.unitId}',
              t.request.functionCode.label,
              l10n.monitorAttempts(t.attempts),
              if (t.latency != null) '${t.latency!.inMilliseconds} ms',
              if (error == null) l10n.monitorResultOk,
            ].join(' · '),
            style: theme.textTheme.bodySmall!.mono,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Builder(
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
          ],
        ],
      ],
    );
  }
}
