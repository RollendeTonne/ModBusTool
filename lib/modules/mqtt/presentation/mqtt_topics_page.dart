import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/theme/app_theme.dart';
import 'package:modbus_explorer/modules/mqtt/domain/mqtt_message.dart';
import 'package:modbus_explorer/modules/mqtt/domain/payload_codec.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_message_log_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_publish_panel.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_subscriptions_panel.dart';

/// M9: received/sent messages next to subscriptions and publish. The
/// topic tree replaces the plain list in M10.
class MqttTopicsPage extends ConsumerWidget {
  const new({super.key});

  static const wideLayout = 1000.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    void clearLog() =>
        ref.read(mqttMessageLogControllerProvider.notifier).clear();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): clearLog,
        const SingleActivator(LogicalKeyboardKey.keyL, meta: true): clearLog,
      },
      child: Column(
        children: [
          const _NotConnectedBanner(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= wideLayout) {
                  return Row(
                    children: [
                      const Expanded(child: MqttMessageList()),
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: 400,
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: const [
                            MqttSubscriptionsPanel(),
                            SizedBox(height: 12),
                            MqttPublishPanel(),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: [
                          Tab(text: l10n.mqttTabMessages),
                          Tab(text: l10n.mqttTabSubscriptions),
                          Tab(text: l10n.mqttTabPublish),
                        ],
                      ),
                      const Expanded(
                        child: TabBarView(
                          children: [
                            MqttMessageList(),
                            SingleChildScrollView(
                              padding: EdgeInsets.all(12),
                              child: MqttSubscriptionsPanel(),
                            ),
                            SingleChildScrollView(
                              padding: EdgeInsets.all(12),
                              child: MqttPublishPanel(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotConnectedBanner extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(
      mqttConnectionControllerProvider.select((s) => s.isConnected),
    );
    if (connected) return const SizedBox.shrink();
    final l10n = context.l10n;
    return MaterialBanner(
      key: const Key('mqtt.notConnected'),
      content: Text(l10n.mqttNotConnectedHint),
      leading: const Icon(Icons.cloud_off_outlined),
      actions: [
        TextButton(
          onPressed: () => context.go(AppDestination.mqttConnection.path),
          child: Text(l10n.mqttGoToConnection),
        ),
      ],
    );
  }
}

/// Newest first; virtualized, so thousands of entries scroll smoothly.
class MqttMessageList extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final log = ref.watch(mqttMessageLogControllerProvider);
    final controller = ref.read(mqttMessageLogControllerProvider.notifier);
    final messages = log.messages;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mqttMessagesCount(messages.length, log.total),
                  key: const Key('mqtt.messageCount'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                key: const Key('mqtt.pause'),
                tooltip: log.paused ? l10n.mqttResume : l10n.mqttPause,
                icon: Icon(log.paused ? Icons.play_arrow : Icons.pause),
                onPressed: () => controller.setPaused(paused: !log.paused),
              ),
              IconButton(
                key: const Key('mqtt.clear'),
                tooltip: '${l10n.mqttClear} (${_clearShortcut()})',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: controller.clear,
              ),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? Center(child: Text(l10n.mqttNoMessages))
              : ListView.builder(
                  key: const Key('mqtt.messageList'),
                  itemCount: messages.length,
                  itemExtent: 56,
                  itemBuilder: (context, i) => _MessageRow(
                    record: messages[messages.length - 1 - i],
                    key: ValueKey(messages.length - 1 - i + log.total),
                  ),
                ),
        ),
      ],
    );
  }

  static String _clearShortcut() =>
      defaultTargetPlatform == TargetPlatform.macOS ? '⌘L' : 'Ctrl+L';
}

class _MessageRow extends StatelessWidget {
  const new({required this.record, super.key});

  final MqttMessageRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall!.mono;
    final t = record.timestamp;
    String two(int n) => n.toString().padLeft(2, '0');
    final time =
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.'
        '${t.millisecond.toString().padLeft(3, '0')}';
    final sent = record.direction == MqttDirection.sent;
    final flags = [
      'QoS ${record.qos.value}',
      if (record.retain) 'R',
      if (record.duplicate) 'DUP',
      '${record.payload.length} B',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Tooltip(
            message: sent ? l10n.mqttTx : l10n.mqttRx,
            child: Icon(
              sent ? Icons.north_east : Icons.south_west,
              size: 18,
              color: sent
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        record.topic,
                        style: mono.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Shrinks first on narrow screens; the topic matters more.
                    Flexible(
                      flex: 2,
                      child: Text(
                        '$time · $flags',
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  payloadPreview(record.payload),
                  style: mono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
