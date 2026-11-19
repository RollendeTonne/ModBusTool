import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_texts.dart';

class MqttStatusChip extends ConsumerWidget {
  const new({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      mqttConnectionControllerProvider.select((s) => s.status),
    );
    final (label, icon, color) = mqttStatusLook(context, status);
    void open() => context.go(AppDestination.mqttConnection.path);
    return Semantics(
      label: context.l10n.mqttStatusLabel(label),
      button: true,
      excludeSemantics: true,
      child: compact
          ? IconButton(
              key: const Key('mqtt.statusChip'),
              tooltip: label,
              icon: Icon(icon, color: color),
              onPressed: open,
            )
          : ActionChip(
              key: const Key('mqtt.statusChip'),
              avatar: Icon(icon, size: 18, color: color),
              label: Text(label),
              side: BorderSide(color: color),
              onPressed: open,
            ),
    );
  }
}
