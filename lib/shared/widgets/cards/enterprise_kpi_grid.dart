import 'package:flutter/material.dart';

import '../../../core/theme/spacing.dart';
import '../../responsive/pharma_screen_layout.dart';
import 'enterprise_stat_card.dart';

export 'enterprise_stat_card.dart';

/// Grelha de KPIs com altura fixa — alinhada à movimentações (88px desktop).
class EnterpriseKpiGrid extends StatelessWidget {
  const EnterpriseKpiGrid({
    super.key,
    required this.cards,
    this.useDesktopRowWhenSingleLine = false,
  });

  final List<Widget> cards;
  final bool useDesktopRowWhenSingleLine;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final s = context.spacing;
    final screen = context.pharmaScreen;
    final cardHeight = PharmaScreenLayout.kpiCardHeight(screen);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = PharmaScreenLayout.kpiCrossAxisCount(constraints.maxWidth);
        final fitsSingleRow = cards.length <= cross;

        if (useDesktopRowWhenSingleLine &&
            screen == PharmaScreenSize.desktop &&
            fitsSingleRow) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(
                  child: SizedBox(
                    height: cardHeight,
                    child: cards[i],
                  ),
                ),
                if (i < cards.length - 1) SizedBox(width: s.sm),
              ],
            ],
          );
        }

        final spacing = screen == PharmaScreenSize.mobile ? 10.0 : s.sm;
        final totalSpacing = spacing * (cross - 1);
        final itemWidth = constraints.maxWidth.isFinite
            ? ((constraints.maxWidth - totalSpacing) / cross).clamp(120.0, double.infinity)
            : 240.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: itemWidth,
                height: cardHeight,
                child: card,
              ),
          ],
        );
      },
    );
  }
}

/// KPI compacto para painéis — densidade e tipografia do design system.
EnterpriseStatCard dashboardKpiCard({
  required String title,
  required String value,
  required IconData icon,
  StatCardAccent accent = StatCardAccent.neutral,
  String? subtitle,
}) {
  return EnterpriseStatCard(
    title: title,
    value: value,
    icon: icon,
    accent: accent,
    subtitle: subtitle,
    density: StatCardDensity.compact,
  );
}
