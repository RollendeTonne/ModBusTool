import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';
import 'package:modbus_explorer/core/theme/app_colors.dart';
import 'package:modbus_explorer/core/widgets/planned_feature_view.dart';

class ConnectionPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final caps = ref.watch(platformCapabilitiesProvider);
    return PlannedFeatureView(
      icon: Icons.cable,
      description: l10n.connectionPageDescription,
      milestone: 'M4',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  l10n.availableTransports,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              _TransportTile(
                label: l10n.transportTcp,
                available: caps.supportsTcp,
              ),
              _TransportTile(
                label: l10n.transportRtu,
                available: caps.supportsRtu,
                hint: caps.supportsRtu ? null : l10n.transportUnavailableHint,
              ),
              _TransportTile(
                label: l10n.transportRtuOverTcp,
                available: caps.supportsRtuOverTcp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransportTile extends StatelessWidget {
  const new({required this.label, required this.available, this.hint});

  final String label;
  final bool available;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = available
        ? context.appColors.success
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      enabled: available,
      leading: Icon(available ? Icons.check_circle : Icons.block, color: color),
      title: Text(label),
      subtitle: Text(hint ?? (available ? l10n.available : l10n.unavailable)),
    );
  }
}
