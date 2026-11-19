import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';

/// Error title, plain-language hint and optional collapsible technical
/// detail. Consistent everywhere errors are shown.
class ErrorPanel extends StatefulWidget {
  const new({
    required this.title,
    required this.hint,
    this.detail,
    this.actions = const [],
    this.dense = false,
    super.key,
  });

  final String title;
  final String hint;
  final String? detail;
  final List<Widget> actions;
  final bool dense;

  @override
  State<ErrorPanel> createState() => _ErrorPanelState();
}

class _ErrorPanelState extends State<ErrorPanel> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = widget.detail;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(widget.dense ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
                ...widget.actions,
              ],
            ),
            if (widget.hint.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.hint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ],
            if (detail != null && detail.isNotEmpty) ...[
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => setState(() => _showDetail = !_showDetail),
                icon: Icon(_showDetail ? Icons.expand_less : Icons.expand_more),
                label: Text(context.l10n.errorDetails),
              ),
              if (_showDetail)
                SelectableText(
                  detail,
                  style: theme.textTheme.bodySmall!.mono.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
