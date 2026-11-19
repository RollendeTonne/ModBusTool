import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/widgets/breakpoints.dart';
import 'package:modbus_explorer/core/widgets/connection_status_chip.dart';

/// Navigation rail on wide windows, bottom navigation bar on phones.
class AdaptiveShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) => navigationShell.goBranch(
    index,
    // Re-selecting the active tab returns to its root route.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    const destinations = AppDestination.values;
    final current = destinations[navigationShell.currentIndex];

    final appBar = AppBar(
      title: Text(current.label(l10n)),
      actions: const [ConnectionStatusChip(), SizedBox(width: 12)],
    );

    if (width < Breakpoints.medium) {
      return Scaffold(
        appBar: appBar,
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelect,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label(l10n),
              ),
          ],
        ),
      );
    }

    final extended = width >= Breakpoints.expanded;
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onSelect,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label(l10n)),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
