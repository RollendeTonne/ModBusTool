import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';

/// Top-level navigation targets; order = navigation order.
enum AppDestination {
  connection('/connection', Icons.cable_outlined, Icons.cable),
  registers('/registers', Icons.table_chart_outlined, Icons.table_chart),
  monitor('/monitor', Icons.receipt_long_outlined, Icons.receipt_long),
  tools('/tools', Icons.handyman_outlined, Icons.handyman),
  settings('/settings', Icons.settings_outlined, Icons.settings);

  new(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    AppDestination.connection => l10n.navConnection,
    AppDestination.registers => l10n.navRegisters,
    AppDestination.monitor => l10n.navMonitor,
    AppDestination.tools => l10n.navTools,
    AppDestination.settings => l10n.navSettings,
  };
}
