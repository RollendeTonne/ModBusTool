import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/widgets/adaptive_shell.dart';
import 'package:modbus_explorer/features/settings/presentation/settings_page.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_page.dart';
import 'package:modbus_explorer/modules/modbus/monitor/presentation/monitor_page.dart';
import 'package:modbus_explorer/modules/modbus/registers/presentation/registers_page.dart';
import 'package:modbus_explorer/modules/modbus/tools/presentation/tools_page.dart';

GoRouter createAppRouter({String initialLocation = '/connection'}) {
  Widget pageFor(AppDestination destination) => switch (destination) {
    AppDestination.connection => const ConnectionPage(),
    AppDestination.registers => const RegistersPage(),
    AppDestination.monitor => const MonitorPage(),
    AppDestination.tools => const ToolsPage(),
    AppDestination.settings => const SettingsPage(),
  };

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
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
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});
