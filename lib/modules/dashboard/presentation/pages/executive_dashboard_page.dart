import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';

class ExecutiveDashboardPage extends StatelessWidget {
  const ExecutiveDashboardPage({super.key});

  static const _kpis = <EnterpriseStatCard>[
    EnterpriseStatCard(
      title: 'Vendas hoje',
      value: '28 400 MT',
      icon: Icons.show_chart,
      subtitle: 'PDV',
      accent: StatCardAccent.positive,
      badge: 'LIVE',
    ),
    EnterpriseStatCard(
      title: 'Alertas sanitários',
      value: '3',
      icon: Icons.warning_amber_outlined,
      subtitle: 'Atenção',
      accent: StatCardAccent.warning,
    ),
    EnterpriseStatCard(
      title: 'Stock crítico',
      value: '12 SKU',
      icon: Icons.inventory_2_outlined,
      subtitle: 'Reposição',
      accent: StatCardAccent.danger,
    ),
    EnterpriseStatCard(
      title: 'Psicotrópicos',
      value: '0 pend.',
      icon: Icons.verified_user_outlined,
      subtitle: 'Livro OK',
      accent: StatCardAccent.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final size = context.pharmaScreen;
    final isMobile = size == PharmaScreenSize.mobile;
    final density = size == PharmaScreenSize.desktop ? StatCardDensity.comfortable : StatCardDensity.compact;

    final kpiChildren = _kpis
        .map(
          (c) => EnterpriseStatCard(
            title: c.title,
            value: c.value,
            icon: c.icon,
            subtitle: c.subtitle,
            accent: c.accent,
            badge: c.badge,
            density: density,
            onTap: c.onTap,
          ),
        )
        .toList();

    final chartCore = LayoutBuilder(
      builder: (context, c) {
        final baseH = switch (size) {
          PharmaScreenSize.mobile => 150.0,
          PharmaScreenSize.tablet => 190.0,
          PharmaScreenSize.desktop => 210.0,
        };
        final maxChart = c.maxHeight.isFinite ? c.maxHeight - 36 : baseH;
        final chartH = (maxChart < baseH ? maxChart : baseH).clamp(120.0, 320.0);
        return SizedBox(
          height: chartH,
          width: double.infinity,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(color: t.border.withValues(alpha: 0.22), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 2),
                    FlSpot(1, 3.2),
                    FlSpot(2, 2.8),
                    FlSpot(3, 4.1),
                    FlSpot(4, 3.6),
                    FlSpot(5, 5.2),
                    FlSpot(6, 4.9),
                    FlSpot(7, 6.1),
                  ],
                  isCurved: true,
                  color: t.brandGreen,
                  barWidth: size == PharmaScreenSize.mobile ? 2.2 : 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: t.brandGreen.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final chartCard = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        isMobile ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'VOLUME DE VENDAS (HOJE)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: t.textMuted,
                  letterSpacing: isMobile ? 1.2 : 2,
                  fontSize: isMobile ? 9 : null,
                ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          chartCore,
        ],
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.brandGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'EXECUTIVE DASHBOARD',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                  fontSize: isMobile ? 16 : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Text(
                      'Farmácia Central • T#01',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: t.textMuted,
                            fontSize: isMobile ? 11 : null,
                          ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                FilledButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.arrow_outward, size: t.iconSm),
                  label: const Text('Exportar'),
                )
              else
                IconButton(
                  tooltip: 'Exportar',
                  onPressed: () {},
                  icon: Icon(Icons.share_outlined, color: t.brandGreen),
                ),
            ],
          ),
          SizedBox(height: isMobile ? AppSpacing.md : 20),
          LayoutBuilder(
            builder: (context, c) {
              final cross = PharmaScreenLayout.kpiCrossAxisCount(c.maxWidth);
              final aspect = PharmaScreenLayout.kpiChildAspectRatio(size);
              return GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: isMobile ? 8 : 14,
                mainAxisSpacing: isMobile ? 8 : 14,
                childAspectRatio: aspect,
                children: kpiChildren,
              );
            },
          ),
          SizedBox(height: isMobile ? AppSpacing.md : 20),
          if (isMobile)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 4),
                initiallyExpanded: false,
                title: Text(
                  'Gráfico de vendas',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: t.textSecondary,
                      ),
                ),
                children: [chartCard],
              ),
            )
          else
            chartCard,
        ],
      ),
    );
  }
}
