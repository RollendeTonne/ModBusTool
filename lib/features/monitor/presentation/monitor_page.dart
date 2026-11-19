import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/core/widgets/planned_feature_view.dart';

class MonitorPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => PlannedFeatureView(
    icon: Icons.receipt_long,
    description: context.l10n.monitorPageDescription,
    milestone: 'M6',
  );
}
