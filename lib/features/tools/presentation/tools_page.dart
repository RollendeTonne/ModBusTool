import 'package:material_ui/material_ui.dart';
import 'package:modbus_explorer/core/l10n/l10n.dart';
import 'package:modbus_explorer/features/tools/presentation/hex_calculator_view.dart';
import 'package:modbus_explorer/features/tools/presentation/scanner_view.dart';
import 'package:modbus_explorer/features/tools/presentation/statistics_view.dart';
import 'package:modbus_explorer/features/tools/presentation/trend_view.dart';

class ToolsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 4,
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
