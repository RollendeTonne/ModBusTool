import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/routing/active_module.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/storage/key_value_store.dart';
import 'package:modbus_explorer/core/widgets/adaptive_shell.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_page.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_page.dart';
import 'package:modbus_explorer/modules/modbus/monitor/presentation/monitor_page.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_page.dart';
import 'package:modbus_explorer/modules/modbus/tools/presentation/tools_page.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_connection_page.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_monitor_page.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_tools_page.dart';
import 'package:modbus_explorer/modules/mqtt/presentation/mqtt_topics_page.dart';

GoRouter createAppRouter({String initialLocation = '/modbus/connection'}) {
  Widget pageFor(AppDestination destination) => switch (destination) {
    AppDestination.modbusConnection => const ConnectionPage(),
    AppDestination.modbusRegisters => const RegistersPage(),
    AppDestination.modbusMonitor => const MonitorPage(),
    AppDestination.modbusTools => const ToolsPage(),
    AppDestination.mqttConnection => const MqttConnectionPage(),
    AppDestination.mqttTopics => const MqttTopicsPage(),
    AppDestination.mqttMonitor => const MqttMonitorPage(),
    AppDestination.mqttTools => const MqttToolsPage(),
    AppDestination.settings => const SettingsPage(),
  };

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      // One shell for both modules: the indexed stack keeps every tab of
      // every module alive (MQTT keeps receiving while Modbus is shown).
      // Indexed stack keeps each tab's state (scroll position, inputs, live
      // log) alive while switching tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdaptiveShell(navigationShell: navigationShell),
        branches: [
          for (final destination in AppDestination.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: destination.path,
                  name: destination.name,
                  builder: (context, state) => pageFor(destination),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Start in the module used last.
  final module = ActiveModuleController.stored(ref.read(keyValueStoreProvider));
  final router = createAppRouter(
    initialLocation: AppDestination.visibleFor(module).first.path,
  );
  ref.onDispose(router.dispose);
  return router;
});
