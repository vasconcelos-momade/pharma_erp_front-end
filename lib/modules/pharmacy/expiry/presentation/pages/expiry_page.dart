import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../lots/presentation/widgets/open_lote_details.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';
import '../providers/expiry_provider.dart';

class ExpiryPage extends ConsumerStatefulWidget {
  const ExpiryPage({super.key});

  @override
  ConsumerState<ExpiryPage> createState() => _ExpiryPageState();
}

class _ExpiryPageState extends ConsumerState<ExpiryPage> {
  final _search = TextEditingController();

  static const _bucketOptions = <(String, String)>[
    ('expirado', 'Expirados'),
    ('30', '30d'),
    ('60', '60d'),
    ('todos', 'Todos'),
  ];

  @override
  void initState() {
    super.initState();
    ref.listenManual(expiryViewProvider, (previous, next) {
      final query = next.valueOrNull?.query;
      if (query != null && _search.text != query) {
        _search.text = query;
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color _rowColor(BuildContext context, String? estado) {
    final t = context.pharmaTokens;
    switch (estado) {
      case 'EXPIRADO':
        return t.posDanger;
      case 'ATE_30_DIAS':
        return Colors.orange;
      case 'ATE_60_DIAS':
        return Colors.amber.shade700;
      default:
        return t.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(expiryViewProvider);
    final controller = ref.read(expiryViewProvider.notifier);
    final state = asyncState.valueOrNull;
    final dash = state?.dashboard;
    final s = context.spacing;
    final reportQuery = <String, dynamic>{
      if ((state?.query ?? '').isNotEmpty) 'q': state!.query,
      'bucket': state?.bucket ?? 'todos',
    };

    return EnterpriseModuleHub(
      actions: [
        ...pharmacyReportActions(
          ref: ref,
          enabled: !asyncState.isLoading,
          path: ReportPaths.expiry,
          queryParameters: reportQuery,
        ),
        IconButton(
          onPressed: () => controller.refresh(force: true),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      kpis: dash == null
          ? null
          : [
              EnterpriseStatCard(
                title: 'Expirados',
                value: '${dash['lotesExpirados'] ?? 0}',
                icon: Icons.warning_amber_rounded,
              ),
              EnterpriseStatCard(
                title: '30 dias',
                value: '${dash['expiramEm30Dias'] ?? 0}',
                icon: Icons.schedule,
              ),
              EnterpriseStatCard(
                title: '60 dias',
                value: '${dash['expiramEm60Dias'] ?? 0}',
                icon: Icons.calendar_month_outlined,
              ),
              EnterpriseStatCard(
                title: 'Valor em risco',
                value: '${dash['valorFinanceiroEmRisco'] ?? 0} MZN',
                icon: Icons.payments_outlined,
              ),
            ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _search,
              onSubmitted: controller.setSearch,
              decoration: const InputDecoration(
                hintText: 'Pesquisar produto ou lote...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ..._bucketOptions.map(
            (option) => FilterChip(
              label: Text(option.$2),
              selected: (state?.bucket ?? 'todos') == option.$1,
              onSelected: (_) => controller.setBucket(option.$1),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          if (asyncState.isLoading) const LinearProgressIndicator(),
          if (asyncState.hasError)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: Text(
                asyncState.error.toString(),
                style: TextStyle(color: context.pharmaTokens.posDanger),
              ),
            ),
          SizedBox(height: s.sm),
          Expanded(
            child: _buildTableContent(
              context: context,
              asyncState: asyncState,
              state: state,
            ),
          ),
          MovimentacoesPagination(
            page: state?.page ?? 1,
            pageSize: state?.pageSize ?? 20,
            hasMore: state?.hasMore ?? false,
            isBusy: asyncState.isLoading,
            onPrev: (state?.page ?? 1) > 1
                ? () => controller.goToPage((state?.page ?? 1) - 1)
                : null,
            onNext: state?.hasMore == true
                ? () => controller.goToPage((state?.page ?? 1) + 1)
                : null,
            onPageSizeChanged: controller.setPageSize,
          ),
          if (state?.totalCount != null)
            Text(
              'Total: ${state!.totalCount} lote(s)',
              style: TextStyle(color: context.pharmaTokens.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildTableContent({
    required BuildContext context,
    required AsyncValue<ExpiryViewState> asyncState,
    required ExpiryViewState? state,
  }) {
    if (asyncState.isLoading && state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = state?.items ?? const <Map<String, dynamic>>[];
    if (items.isEmpty) {
      return Center(
        child: Text(
          state?.bucket == 'todos'
              ? 'Nenhum lote com stock activo.'
              : 'Nenhum lote neste filtro de validade.',
          style: TextStyle(color: context.pharmaTokens.textMuted),
        ),
      );
    }

    return EnterpriseDataTable(
      columns: const [
        DataColumn(label: Text('PRODUTO')),
        DataColumn(label: Text('LOTE')),
        DataColumn(label: Text('VALIDADE')),
        DataColumn(label: Text('DIAS')),
        DataColumn(label: Text('QTD')),
        DataColumn(label: Text('VALOR')),
        DataColumn(label: Text('ESTADO')),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final item = items[index];
        final color = _rowColor(context, item['estado'] as String?);
        return DataRow(
          onSelectChanged: (_) => _openLotDrawer(item['id']?.toString() ?? ''),
          cells: [
            DataCell(Text(item['produtoNome']?.toString() ?? '—')),
            DataCell(Text(item['numeroLote']?.toString() ?? '—')),
            DataCell(Text(_formatDate(item['dataValidade']))),
            DataCell(
              Text(
                '${item['diasRestantes'] ?? '—'}',
                style: TextStyle(color: color),
              ),
            ),
            DataCell(Text(item['quantidadeDisponivel']?.toString() ?? '0')),
            DataCell(Text(item['valorEmStock']?.toString() ?? '0')),
            DataCell(Text(item['estado']?.toString() ?? '—')),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '—';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Future<void> _openLotDrawer(String loteId) => openLoteDetails(context, loteId);
}

