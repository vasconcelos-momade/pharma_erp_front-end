import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';

/// Painel operacional farmácia: validade, FEFO, psicotrópicos e stock crítico.
class PharmacyDashboardPage extends StatelessWidget {
  const PharmacyDashboardPage({super.key});

  static const double _chartBreak = 520;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return EnterpriseModuleHub(
      title: 'Painel da farmácia',
      subtitle: 'Alertas sanitários, FEFO, psicotrópicos e stock crítico em tempo real.',
      tag: 'Painéis',
      kpis: const [
        EnterpriseStatCard(title: 'Itens < 30d validade', value: '18', icon: Icons.event_busy, accent: StatCardAccent.warning),
        EnterpriseStatCard(title: 'Stock crítico', value: '12 SKU', icon: Icons.inventory_2_outlined, accent: StatCardAccent.danger),
        EnterpriseStatCard(title: 'Psicotrópicos pendentes', value: '0', icon: Icons.verified_user_outlined, accent: StatCardAccent.positive),
        EnterpriseStatCard(title: 'FEFO activo', value: '100%', icon: Icons.account_tree, accent: StatCardAccent.info),
      ],
      child: LayoutBuilder(
        builder: (context, bx) {
          final narrow = bx.maxWidth < _chartBreak;
          final maxH = bx.maxHeight.isFinite ? bx.maxHeight : 400.0;
          if (narrow) {
            const gap = AppSpacing.md;
            final inner = maxH > gap ? maxH - gap : maxH;
            final each = (inner / 2).clamp(100.0, 260.0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: each, child: _MiniBars(t: t, title: 'Saídas por classe (7d)')),
                const SizedBox(height: gap),
                SizedBox(height: each, child: _ExpiryDonut(t: t)),
              ],
            );
          }
          final rowH = maxH.clamp(160.0, 320.0);
          return SizedBox(
            height: rowH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _MiniBars(t: t, title: 'Saídas por classe (7d)')),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: _ExpiryDonut(t: t)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.t, required this.title});

  final PharmaTokens t;
  final String title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.border.withValues(alpha: 0.65)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.textMuted, letterSpacing: 2),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, m) => Text(
                            ['Geral', 'Antibiót.', 'MIP', 'OTC'][v.toInt().clamp(0, 3)],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 8, color: t.textMuted, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
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
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: [
                      _g(0, 5.2, t.brandBlue),
                      _g(1, 3.1, t.brandGreen),
                      _g(2, 4.4, t.posWarning),
                      _g(3, 6.8, t.psychotropic),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BarChartGroupData _g(int x, double y, Color c) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 12,
          borderRadius: BorderRadius.circular(4),
          color: c,
        ),
      ],
    );
  }
}

class _ExpiryDonut extends StatelessWidget {
  const _ExpiryDonut({required this.t});

  final PharmaTokens t;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.border.withValues(alpha: 0.65)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURVA DE VALIDADE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.textMuted, letterSpacing: 2),
              ),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: c.maxWidth > 200 ? 42 : 28,
                    sections: [
                      PieChartSectionData(
                        value: 62,
                        title: 'OK',
                        color: t.brandGreen,
                        radius: c.maxWidth > 200 ? 48 : 36,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: 22,
                        title: '30d',
                        color: t.posWarning,
                        radius: c.maxWidth > 200 ? 48 : 36,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      PieChartSectionData(
                        value: 16,
                        title: 'Crít.',
                        color: t.posDanger,
                        radius: c.maxWidth > 200 ? 48 : 36,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
