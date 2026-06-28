import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../providers/movimentacao_provider.dart';
import '../widgets/movimentacoes_body.dart';
import '../widgets/stock_report_exports.dart';
import '../../domain/entities/movimentacao.dart';

class MovimentacoesHubPage extends ConsumerStatefulWidget {
  const MovimentacoesHubPage({super.key});

  @override
  ConsumerState<MovimentacoesHubPage> createState() =>
      _MovimentacoesHubPageState();
}

class _MovimentacoesHubPageState extends ConsumerState<MovimentacoesHubPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(movimentacaoListProvider).query.search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _reportPath(MovimentacaoQuery query) {
    switch (query.tipo) {
      case 'ENTRADA':
        return ReportPaths.stockMovementsEntrada;
      case 'SAIDA':
        return ReportPaths.stockMovementsSaida;
      case 'AJUSTE':
        return ReportPaths.stockMovementsAjuste;
      default:
        return ReportPaths.stockMovements;
    }
  }

  Map<String, dynamic> _reportQuery(MovimentacaoQuery query) {
    return {
      if (query.search.isNotEmpty) 'q': query.search,
      if (query.tipo != null) 'tipo': query.tipo,
      if (query.origem != null) 'origem': query.origem,
      if (query.dataInicio != null) 'dataInicio': formatReportDate(query.dataInicio!),
      if (query.dataFim != null) 'dataFim': formatReportDate(query.dataFim!),
    };
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(movimentacaoListProvider);
    final s = context.spacing;

    ref.listen<MovimentacaoListState>(movimentacaoListProvider, (previous, next) {
      if (_searchController.text != next.query.search) {
        _searchController.value = TextEditingValue(
          text: next.query.search,
          selection: TextSelection.collapsed(offset: next.query.search.length),
        );
      }
    });

    final reportQuery = _reportQuery(listState.query);

    return EnterpriseModuleHub(
      title: 'Movimentos de stock',
      subtitle: 'Entradas, saídas, ajustes e trilho de auditoria.',
      tag: 'Stock',
      actions: [
        ...stockReportActions(
          ref: ref,
          enabled: listState.isInitialized && !listState.isBusy,
          path: _reportPath(listState.query),
          queryParameters: reportQuery,
        ),
      ],
      child: Column(
        children: [
          if (stockReportError(ref) != null)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: stockReportError(ref),
            ),
          Expanded(
            child: MovimentacoesBody(
              searchController: _searchController,
              listState: listState,
            ),
          ),
        ],
      ),
    );
  }
}
