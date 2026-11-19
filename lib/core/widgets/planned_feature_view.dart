import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';

/// Empty state for areas implemented in later milestones.
class PlannedFeatureView extends StatelessWidget {
  const new({
    required this.icon,
    required this.description,
    required this.milestone,
    this.child,
    super.key,
  });

  final IconData icon;
  final String description;
  final String milestone;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                description,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.plannedFeatureMilestone(milestone),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (child != null) ...[const SizedBox(height: 24), child!],
            ],
          ),
        ),
      ),
    );
  }
}
