import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';

/// Painel financeiro: caixa, despesas e tesouraria.
class FinanceDashboardPage extends StatelessWidget {
  const FinanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Painel financeiro',
      subtitle: 'Receitas, despesas, caixa e conciliação multi-terminal.',
      tag: 'Painéis',
      kpis: const [
        EnterpriseStatCard(title: 'Receitas 7d', value: '1,02M MT', icon: Icons.trending_up, accent: StatCardAccent.positive),
        EnterpriseStatCard(title: 'Despesas 7d', value: '214k MT', icon: Icons.trending_down, accent: StatCardAccent.warning),
        EnterpriseStatCard(title: 'Margem', value: '28%', icon: Icons.percent, accent: StatCardAccent.info),
        EnterpriseStatCard(title: 'Caixa em tempo real', value: '412k MT', icon: Icons.account_balance_wallet, accent: StatCardAccent.positive),
      ],
      child: LayoutBuilder(
        builder: (context, bx) {
          final h = bx.maxHeight.isFinite ? bx.maxHeight : 300.0;
          final w = bx.maxWidth.isFinite ? bx.maxWidth : 400.0;
          return Container(
            width: w,
            height: h,
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(t.radiusMd),
              border: Border.all(color: t.border.withValues(alpha: 0.65)),
            ),
            clipBehavior: Clip.hardEdge,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (v) => FlLine(color: t.border.withValues(alpha: 0.25), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, m) => Text(
                        'D${v.toInt() + 1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: t.textMuted, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}k',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: t.textMuted),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 12),
                      FlSpot(1, 18),
                      FlSpot(2, 14),
                      FlSpot(3, 22),
                      FlSpot(4, 26),
                      FlSpot(5, 24),
                      FlSpot(6, 30),
                    ],
                    isCurved: true,
                    color: t.brandGreen,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: t.brandGreen.withValues(alpha: 0.12),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 8),
                      FlSpot(1, 9),
                      FlSpot(2, 11),
                      FlSpot(3, 10),
                      FlSpot(4, 12),
                      FlSpot(5, 13),
                      FlSpot(6, 12),
                    ],
                    isCurved: true,
                    color: t.brandBlue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
