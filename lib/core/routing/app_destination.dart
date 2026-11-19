import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/shared/profiles/protocol_module.dart';

/// Navigation targets of all modules; order = navigation order within a
/// module. [module] `null` = shared by every module (settings).
enum AppDestination {
  modbusConnection(
    ProtocolModule.modbus,
    '/modbus/connection',
    Icons.cable_outlined,
    Icons.cable,
  ),
  modbusRegisters(
    ProtocolModule.modbus,
    '/modbus/registers',
    Icons.table_chart_outlined,
    Icons.table_chart,
  ),
  modbusMonitor(
    ProtocolModule.modbus,
    '/modbus/monitor',
    Icons.receipt_long_outlined,
    Icons.receipt_long,
  ),
  modbusTools(
    ProtocolModule.modbus,
    '/modbus/tools',
    Icons.handyman_outlined,
    Icons.handyman,
  ),
  mqttConnection(
    ProtocolModule.mqtt,
    '/mqtt/connection',
    Icons.dns_outlined,
    Icons.dns,
  ),
  mqttTopics(
    ProtocolModule.mqtt,
    '/mqtt/topics',
    Icons.account_tree_outlined,
    Icons.account_tree,
  ),
  mqttMonitor(
    ProtocolModule.mqtt,
    '/mqtt/monitor',
    Icons.receipt_long_outlined,
    Icons.receipt_long,
  ),
  mqttTools(
    ProtocolModule.mqtt,
    '/mqtt/tools',
    Icons.handyman_outlined,
    Icons.handyman,
  ),
  settings(null, '/settings', Icons.settings_outlined, Icons.settings);

  new(this.module, this.path, this.icon, this.selectedIcon);

  final ProtocolModule? module;
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  /// What the navigation shows while [module] is active.
  static List<AppDestination> visibleFor(ProtocolModule module) => [
    for (final d in values)
      if (d.module == null || d.module == module) d,
  ];

  String label(AppLocalizations l10n) => switch (this) {
    modbusConnection || mqttConnection => l10n.navConnection,
    modbusRegisters => l10n.navRegisters,
    modbusMonitor || mqttMonitor => l10n.navMonitor,
    modbusTools || mqttTools => l10n.navTools,
    mqttTopics => l10n.navTopics,
    settings => l10n.navSettings,
  };
}

extension ProtocolModuleLabel on ProtocolModule {
  String label(AppLocalizations l10n) => switch (this) {
    ProtocolModule.modbus => l10n.moduleModbus,
    ProtocolModule.mqtt => l10n.moduleMqtt,
  };

  IconData get icon => switch (this) {
    ProtocolModule.modbus => Icons.memory,
    ProtocolModule.mqtt => Icons.hub_outlined,
  };
}
