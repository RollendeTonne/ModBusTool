import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/platform/platform_capabilities.dart';
import 'package:modbus_explorer/features/connection/domain/connection_profile.dart';

extension ConnectionKindUi on ConnectionKind {
  IconData get icon => switch (this) {
    ConnectionKind.tcp => Icons.lan_outlined,
    ConnectionKind.rtu => Icons.usb,
    ConnectionKind.rtuOverTcp => Icons.router_outlined,
    ConnectionKind.simulator => Icons.science_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ConnectionKind.tcp => l10n.connectionKindTcp,
    ConnectionKind.rtu => l10n.connectionKindRtu,
    ConnectionKind.rtuOverTcp => l10n.connectionKindRtuOverTcp,
    ConnectionKind.simulator => l10n.connectionKindSimulator,
  };

  bool isAvailable(PlatformCapabilities caps) => switch (this) {
    ConnectionKind.tcp || ConnectionKind.rtuOverTcp => caps.supportsTcp,
    ConnectionKind.rtu => caps.supportsRtu,
    ConnectionKind.simulator => true,
  };
}
