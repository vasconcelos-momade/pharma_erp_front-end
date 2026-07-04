import 'package:flutter/material.dart';

import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
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

    return EnterpriseKpiGrid(cards: cards, useDesktopRowWhenSingleLine: true);
  }

  String _qtyLabel(double quantidade) {
    final normalized = quantidade == quantidade.roundToDouble()
        ? quantidade.toInt().toString()
        : quantidade.toStringAsFixed(2);
    return '$normalized un. movimentadas';
  }
}
