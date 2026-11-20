import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/widgets/resizable_split.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_controller.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_publish_panel.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_subscriptions_panel.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topic_detail.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topic_tree_view.dart';

/// Topic tree | details | subscriptions + publish. Three resizable
/// columns on wide windows, tree + tabs on medium ones, tabs on phones.
class MqttTopicsPage extends ConsumerWidget {
  const new({super.key});

  static const wideLayout = 1000.0;
  static const mediumLayout = 700.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    const side = _SidePanel();
    return Column(
      children: [
        const MqttNotConnectedBanner(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width >= wideLayout) {
                return const ResizableSplit(
                  initialFraction: 0.4,
                  minFirst: 300,
                  minSecond: 600,
                  first: MqttTopicTreeView(),
                  second: ResizableSplit(
                    minFirst: 260,
                    minSecond: 330,
                    first: MqttTopicDetail(),
                    second: side,
                  ),
                );
              }
              final tabs = [
                if (width < mediumLayout) Tab(text: l10n.mqttTabTree),
                Tab(text: l10n.mqttTabDetails),
                Tab(text: l10n.mqttTabSubscriptions),
                Tab(text: l10n.mqttTabPublish),
              ];
              final tabbed = DefaultTabController(
                length: tabs.length,
                child: Builder(
                  builder: (context) => Column(
                    children: [
                      TabBar(tabs: tabs),
                      Expanded(
                        child: TabBarView(
                          children: [
                            if (width < mediumLayout)
                              MqttTopicTreeView(
                                // Phones: a selection opens the details.
                                onSelected: (_) =>
                                    DefaultTabController.of(context)
                                        .animateTo(1),
                              ),
                            const MqttTopicDetail(),
                            const SingleChildScrollView(
                              padding: EdgeInsets.all(12),
                              child: MqttSubscriptionsPanel(),
                            ),
                            const SingleChildScrollView(
                              padding: EdgeInsets.all(12),
                              child: MqttPublishPanel(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
              if (width < mediumLayout) return tabbed;
              return ResizableSplit(
                minFirst: 320,
                minSecond: 340,
                first: const MqttTopicTreeView(),
                second: tabbed,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SidePanel extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: const [
      MqttSubscriptionsPanel(),
      SizedBox(height: 12),
      MqttPublishPanel(),
    ],
  );
}

class MqttNotConnectedBanner extends ConsumerWidget {
  const new({super.key});

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
