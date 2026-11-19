import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/features/network_scan/presentation/network_scan_view.dart';
import 'package:modbus_explorer/modules/modbus/tools/presentation/hex_calculator_view.dart';
import 'package:modbus_explorer/modules/modbus/tools/presentation/scanner_view.dart';
import 'package:modbus_explorer/modules/modbus/tools/presentation/statistics_view.dart';
import 'package:modbus_explorer/modules/modbus/tools/presentation/trend_view.dart';

class ToolsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(
                icon: const Icon(Icons.calculate_outlined),
                text: l10n.toolsHexCalculator,
              ),
              Tab(icon: const Icon(Icons.radar), text: l10n.toolsScanner),
              Tab(
                icon: const Icon(Icons.travel_explore),
                text: l10n.toolsNetwork,
              ),
              Tab(
                icon: const Icon(Icons.insights_outlined),
                text: l10n.toolsStatistics,
              ),
              Tab(icon: const Icon(Icons.show_chart), text: l10n.toolsTrend),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                HexCalculatorView(),
                ScannerView(),
                NetworkScanView(),
                StatisticsView(),
                TrendView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
