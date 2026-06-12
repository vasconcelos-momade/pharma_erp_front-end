import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';

/// Painel de stock: entradas, saídas, perdas e inventário.
class StockDashboardPage extends StatelessWidget {
  const StockDashboardPage({super.key});

  static const double _chartBreak = 520;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Painel de stock',
      subtitle: 'Movimentos, perdas, requisições e progresso de inventário.',
      tag: 'Painéis',
      kpis: const [
        EnterpriseStatCard(title: 'Entradas 7d', value: '1 842', icon: Icons.move_to_inbox, accent: StatCardAccent.info),
        EnterpriseStatCard(title: 'Saídas 7d', value: '2 104', icon: Icons.north_east, accent: StatCardAccent.positive),
        EnterpriseStatCard(title: 'Perdas', value: '0,12%', icon: Icons.delete_outline, accent: StatCardAccent.warning),
        EnterpriseStatCard(title: 'Inventário', value: '64%', icon: Icons.fact_check, accent: StatCardAccent.neutral),
      ],
      child: LayoutBuilder(
        builder: (context, bx) {
          final narrow = bx.maxWidth < _chartBreak;
          final maxH = bx.maxHeight.isFinite ? bx.maxHeight : 400.0;
          final lineCard = _ChartCard(
            t: t,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (v, m) {
                        if ((v - v.round()).abs() > 0.01) return const SizedBox.shrink();
                        return Text(
                          '${v.toInt()}',
                          style: TextStyle(fontSize: 8, color: t.textMuted, fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, m) => Text(
                        'S${v.toInt()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 8, color: t.textMuted, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 5),
                      FlSpot(2, 4),
                      FlSpot(3, 7),
                      FlSpot(4, 6),
                      FlSpot(5, 9),
                    ],
                    isCurved: true,
                    color: t.brandBlue,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          );
          final barCard = _ChartCard(
            t: t,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (v, m) {
                        if ((v - v.round()).abs() > 0.01) return const SizedBox.shrink();
                        return Text(
                          '${v.toInt()}',
                          style: TextStyle(fontSize: 8, color: t.textMuted, fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, m) => Text(
                        'D${v.toInt() + 1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 8, color: t.textMuted, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(
                  6,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: [4, 6, 3, 7, 5, 8][i].toDouble(),
                        width: 10,
                        borderRadius: BorderRadius.circular(3),
                        color: i.isEven ? t.brandGreen : t.posWarning,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          if (narrow) {
            const gap = AppSpacing.md;
            final inner = maxH > gap ? maxH - gap : maxH;
            final each = (inner / 2).clamp(100.0, 280.0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: each, child: lineCard),
                const SizedBox(height: gap),
                SizedBox(height: each, child: barCard),
              ],
            );
          }
          final rowH = maxH.clamp(180.0, 340.0);
          return SizedBox(
            height: rowH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: lineCard),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: barCard),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.t, required this.child});

  final PharmaTokens t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          width: c.maxWidth,
          height: c.maxHeight,
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.border.withValues(alpha: 0.65)),
          ),
          clipBehavior: Clip.hardEdge,
          child: child,
        );
      },
    );
  }
}
