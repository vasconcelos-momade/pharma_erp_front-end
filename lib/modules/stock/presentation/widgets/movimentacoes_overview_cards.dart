import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../domain/entities/movimentacao.dart';

class MovimentacoesOverviewCards extends StatelessWidget {
  const MovimentacoesOverviewCards({
    super.key,
    required this.overview,
    required this.hasFilters,
  });

  final MovimentacaoOverview overview;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final cards = [
      EnterpriseStatCard(
        title: 'Total',
        value: '${overview.totalMovimentos}',
        subtitle: hasFilters ? 'Com filtros activos' : 'No período',
        icon: Icons.swap_horiz_rounded,
        accent: StatCardAccent.info,
        density: StatCardDensity.compact,
      ),
      EnterpriseStatCard(
        title: 'Entradas',
        value: '${overview.entradas.count}',
        subtitle: _qtyLabel(overview.entradas.quantidade),
        icon: Icons.arrow_downward_rounded,
        accent: StatCardAccent.positive,
        density: StatCardDensity.compact,
      ),
      EnterpriseStatCard(
        title: 'Saídas',
        value: '${overview.saidas.count}',
        subtitle: _qtyLabel(overview.saidas.quantidade),
        icon: Icons.arrow_upward_rounded,
        accent: StatCardAccent.warning,
        density: StatCardDensity.compact,
      ),
      EnterpriseStatCard(
        title: 'Ajustes',
        value: '${overview.ajustes.count}',
        subtitle: _qtyLabel(overview.ajustes.quantidade),
        icon: Icons.tune_rounded,
        accent: StatCardAccent.neutral,
        density: StatCardDensity.compact,
      ),
    ];

    if (screen == PharmaScreenSize.desktop) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(
              child: SizedBox(
                height: 88,
                child: cards[i],
              ),
            ),
            if (i < cards.length - 1) SizedBox(width: s.sm),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = switch (screen) {
          PharmaScreenSize.mobile => 2,
          PharmaScreenSize.tablet => 2,
          PharmaScreenSize.desktop => 4,
        };
        final aspect = switch (screen) {
          PharmaScreenSize.mobile => 1.7,
          PharmaScreenSize.tablet => 1.95,
          PharmaScreenSize.desktop => 1.45,
        };

        return GridView.count(
          crossAxisCount: cross,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: screen == PharmaScreenSize.mobile ? 10 : s.sm,
          mainAxisSpacing: screen == PharmaScreenSize.mobile ? 10 : s.sm,
          childAspectRatio: aspect,
          children: cards,
        );
      },
    );
  }

  String _qtyLabel(double quantidade) {
    final normalized = quantidade == quantidade.roundToDouble()
        ? quantidade.toInt().toString()
        : quantidade.toStringAsFixed(2);
    return '$normalized un. movimentadas';
  }
}
