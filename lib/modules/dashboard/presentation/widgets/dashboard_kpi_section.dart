import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';

/// Secção de KPIs com indicadores essenciais e secundários expandíveis.
class DashboardKpiSection extends StatefulWidget {
  const DashboardKpiSection({
    super.key,
    required this.primaryKpis,
    this.secondaryKpis = const [],
    this.expandLabel = 'Mais indicadores',
    this.collapseLabel = 'Menos indicadores',
  });

  final List<EnterpriseStatCard> primaryKpis;
  final List<EnterpriseStatCard> secondaryKpis;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<DashboardKpiSection> createState() => _DashboardKpiSectionState();
}

class _DashboardKpiSectionState extends State<DashboardKpiSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.primaryKpis.isEmpty && widget.secondaryKpis.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.primaryKpis.isNotEmpty)
          EnterpriseKpiGrid(
            cards: widget.primaryKpis,
            useDesktopRowWhenSingleLine: widget.primaryKpis.length <= 5,
          ),
        if (widget.secondaryKpis.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              label: Text(_expanded ? widget.collapseLabel : widget.expandLabel),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            EnterpriseKpiGrid(cards: widget.secondaryKpis),
          ],
        ],
      ],
    );
  }
}
