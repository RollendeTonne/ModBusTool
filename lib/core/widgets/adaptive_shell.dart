import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/routing/active_module.dart';
import 'package:modbus_explorer/core/routing/app_destination.dart';
import 'package:modbus_explorer/core/widgets/breakpoints.dart';
import 'package:modbus_explorer/modules/modbus/connection/presentation/connection_status_chip.dart';
import 'package:modbus_explorer/shared/profiles/protocol_module.dart';

/// Module switcher in the app bar; navigation rail on wide windows, bottom
/// navigation bar on phones, showing the active module's destinations.
class AdaptiveShell extends ConsumerWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  AppDestination get _current =>
      AppDestination.values[navigationShell.currentIndex];

  void _go(WidgetRef ref, AppDestination destination) {
    ref.read(activeModuleProvider.notifier).visited(destination);
    navigationShell.goBranch(
      destination.index,
      // Re-selecting the active tab returns to its root route.
      initialLocation: destination == _current,
    );
  }

  void _switchModule(WidgetRef ref, ProtocolModule module) {
    final controller = ref.read(activeModuleProvider.notifier)
      // Remember where this module was left, also after context.go().
      ..visited(_current)
      ..select(module);
    // Settings are shared: stay there, otherwise return to where the
    // target module was left.
    if (_current.module != null) {
      _go(ref, ref.read(activeModuleProvider).destinationFor(module));
    }
    controller.select(module);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    final current = _current;
    final module = current.module ?? ref.watch(activeModuleProvider).module;
    final destinations = AppDestination.visibleFor(module);
    final selectedIndex = destinations.indexOf(current);

    final compact = width < Breakpoints.medium;
    final appBar = AppBar(
      titleSpacing: compact ? 8 : null,
      title: Row(
        children: [
          Tooltip(
            message: l10n.moduleSwitchTooltip,
            child: SegmentedButton<ProtocolModule>(
              key: const Key('app.moduleSwitch'),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                for (final m in ProtocolModule.values)
                  ButtonSegment(
                    value: m,
                    icon: compact ? null : Icon(m.icon, size: 18),
                    label: Text(m.label(l10n), key: Key('module.${m.name}')),
                  ),
              ],
              selected: {module},
              onSelectionChanged: (s) => _switchModule(ref, s.single),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 16),
            Flexible(
              child: Text(current.label(l10n), overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
      actions: [
        if (module == ProtocolModule.modbus)
          ConnectionStatusChip(compact: compact),
        SizedBox(width: compact ? 4 : 12),
      ],
    );

    final Widget scaffold;
    if (compact) {
      scaffold = Scaffold(
        appBar: appBar,
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => _go(ref, destinations[i]),
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
    } else {
      final extended = width >= Breakpoints.expanded;
      scaffold = Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _go(ref, destinations[i]),
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

    // Ctrl/⌘ + 1…5 switches between the areas of the active module,
    // Ctrl/⌘ + Shift + M between the modules.
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
    ];
    final other = ProtocolModule
        .values[(module.index + 1) % ProtocolModule.values.length];
    return CallbackShortcuts(
      bindings: {
        for (final (i, key) in digits.take(destinations.length).indexed) ...{
          SingleActivator(key, control: true): () => _go(ref, destinations[i]),
          SingleActivator(key, meta: true): () => _go(ref, destinations[i]),
        },
        const SingleActivator(
          LogicalKeyboardKey.keyM,
          control: true,
          shift: true,
        ): () =>
            _switchModule(ref, other),
        const SingleActivator(
          LogicalKeyboardKey.keyM,
          meta: true,
          shift: true,
        ): () =>
            _switchModule(ref, other),
      },
      child: Focus(autofocus: true, child: scaffold),
    );
  }
}
