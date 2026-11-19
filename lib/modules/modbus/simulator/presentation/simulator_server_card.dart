import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/modules/modbus/simulator/presentation/simulator_server_controller.dart';

class SimulatorServerCard extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SimulatorServerCard> createState() =>
      _SimulatorServerCardState();
}

class _SimulatorServerCardState extends ConsumerState<SimulatorServerCard> {
  late final TextEditingController _port = TextEditingController(
    text: '${ref.read(simulatorServerControllerProvider).port}',
  );

  @override
  void dispose() {
    _port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(simulatorServerControllerProvider);
    final controller = ref.read(simulatorServerControllerProvider.notifier);
    final server = state.server;

    final String status;
    if (server != null) {
      final endpoint = '${server.address.address}:${server.port}';
      status =
          '${l10n.simulatorServerRunning(endpoint)} · '
          '${l10n.simulatorServerConnections(server.connectionCount)}';
    } else if (state.error case final error?) {
      status = l10n.simulatorServerStartFailed('$error');
    } else {
      status = l10n.simulatorServerStopped;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.dns_outlined),
              title: Text(l10n.simulatorServerTitle),
              subtitle: Text(l10n.simulatorServerHint),
              value: state.isRunning,
              onChanged: state.isStarting
                  ? null
                  : (on) {
                      if (on) {
                        final port = int.tryParse(_port.text);
                        if (port != null && port > 0 && port < 65536) {
                          unawaited(controller.start(port: port));
                        }
                      } else {
                        unawaited(controller.stop());
                      }
                    },
            ),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _port,
                    enabled: !state.isRunning,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.fieldPort),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.simulatorServerExpose),
                    value: state.exposeOnNetwork,
                    onChanged: state.isRunning
                        ? null
                        : (v) => controller.setExposeOnNetwork(expose: v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: theme.textTheme.bodySmall!.mono.copyWith(
                color: state.error != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
