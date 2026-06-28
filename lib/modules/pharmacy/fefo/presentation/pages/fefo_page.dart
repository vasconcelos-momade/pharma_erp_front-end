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
import '../../../lots/presentation/widgets/lot_detail_drawer.dart';
import '../providers/fefo_provider.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';

class FefoPage extends ConsumerStatefulWidget {
  const FefoPage({super.key});

  @override
  ConsumerState<FefoPage> createState() => _FefoPageState();
}

class _FefoPageState extends ConsumerState<FefoPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  var _tabIndex = 0;

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.index != _tabIndex) {
      setState(() => _tabIndex = _tabs.index);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(fefoViewProvider);
    final controller = ref.read(fefoViewProvider.notifier);
    final state = asyncState.valueOrNull;
    final dash = state?.dashboard;
    final s = context.spacing;
    final t = context.pharmaTokens;

    if (state != null && _search.text != state.query) {
      _search.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    final alerts = <String>[
      if ((dash?['produtosForaFefo'] ?? 0) > 0)
        '${dash?['produtosForaFefo']} produto(s) fora de conformidade FEFO',
      if ((dash?['lotesExpirados'] ?? 0) > 0)
        '${dash?['lotesExpirados']} lote(s) expirado(s) exigem acção',
      if ((dash?['lotesBloqueados'] ?? 0) > 0)
        '${dash?['lotesBloqueados']} lote(s) bloqueado(s) sanitariamente',
    ];
    final reportPath = _tabIndex == 0
        ? ReportPaths.pharmacyFefoOverview
        : ReportPaths.pharmacyFefoAudit;
    final reportQuery = <String, dynamic>{
      if ((state?.query ?? '').isNotEmpty) 'q': state!.query,
      if (_tabIndex == 1 && state?.situacao != null) 'situacao': state!.situacao,
    };

    return EnterpriseModuleHub(
      title: 'FEFO',
      subtitle: 'First Expire, First Out — conformidade e auditoria de lotes.',
      tag: 'Farmácia',
      actions: [
        ...pharmacyReportActions(
          ref: ref,
          enabled: state != null && !asyncState.isLoading,
          path: reportPath,
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
                title: 'Fora FEFO',
                value: '${dash['produtosForaFefo'] ?? 0}',
                icon: Icons.rule_folder_outlined,
              ),
              EnterpriseStatCard(
                title: 'Lotes expirados',
                value: '${dash['lotesExpirados'] ?? 0}',
                icon: Icons.event_busy_outlined,
              ),
              EnterpriseStatCard(
                title: 'Bloqueados',
                value: '${dash['lotesBloqueados'] ?? 0}',
                icon: Icons.block_outlined,
              ),
              EnterpriseStatCard(
                title: 'Alertas',
                value: '${dash['alertasFefo'] ?? 0}',
                icon: Icons.notifications_active_outlined,
              ),
            ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
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
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              initialValue: state?.situacao,
              decoration: const InputDecoration(
                labelText: 'Situação auditoria',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                DropdownMenuItem<String?>(value: 'CONFORME', child: Text('Conforme')),
                DropdownMenuItem<String?>(value: 'VIOLACAO', child: Text('Violação')),
                DropdownMenuItem<String?>(value: 'EXPIRADO', child: Text('Expirado')),
                DropdownMenuItem<String?>(value: 'QUARENTENA', child: Text('Quarentena')),
              ],
              onChanged: controller.setSituacao,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          if (alerts.isNotEmpty)
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: alerts.length,
                separatorBuilder: (_, _) => SizedBox(width: s.sm),
                itemBuilder: (_, index) => _AlertCard(message: alerts[index]),
              ),
            ),
          if (alerts.isNotEmpty) SizedBox(height: s.sm),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Visão geral'),
              Tab(text: 'Auditoria'),
            ],
          ),
          if (asyncState.isLoading) const LinearProgressIndicator(),
          if (asyncState.hasError)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: Text(
                asyncState.error.toString(),
                style: TextStyle(color: t.posDanger),
              ),
            ),
          if (pharmacyReportError(ref) != null)
            Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: pharmacyReportError(ref),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                EnterpriseDataTable(
                  columns: const [
                    DataColumn(label: Text('PRODUTO')),
                    DataColumn(label: Text('LOTE FEFO')),
                    DataColumn(label: Text('VALIDADE')),
                    DataColumn(label: Text('STOCK')),
                    DataColumn(label: Text('SITUAÇÃO')),
                    DataColumn(label: Text('ALERTA')),
                  ],
                  rowCount: state?.overview.length ?? 0,
                  rowBuilder: (context, index) {
                    final item = state!.overview[index];
                    final lote = item['loteRecomendado'] as Map<String, dynamic>?;
                    final loteId = lote?['id']?.toString() ?? item['loteId']?.toString();
                    return DataRow(
                      onSelectChanged: loteId != null && loteId.isNotEmpty
                          ? (_) => _openLotDrawer(loteId)
                          : null,
                      cells: [
                      DataCell(Text(item['produtoNome']?.toString() ?? '—')),
                      DataCell(Text(lote?['numeroLote']?.toString() ?? '—')),
                      DataCell(Text(lote?['dataValidade']?.toString().substring(0, 10) ?? '—')),
                      DataCell(Text(lote?['stock']?.toString() ?? '0')),
                      DataCell(Text(item['situacao']?.toString() ?? '—')),
                      DataCell(Text(_alertLabel(item['situacao']?.toString()))),
                    ],
                    );
                  },
                ),
                EnterpriseDataTable(
                  columns: const [
                    DataColumn(label: Text('PRODUTO')),
                    DataColumn(label: Text('LOTE USADO')),
                    DataColumn(label: Text('LOTE CORRECTO')),
                    DataColumn(label: Text('UTILIZADOR')),
                    DataColumn(label: Text('DATA')),
                    DataColumn(label: Text('SITUAÇÃO')),
                    DataColumn(label: Text('MOTIVO')),
                  ],
                  rowCount: state?.audit.length ?? 0,
                  rowBuilder: (context, index) {
                    final item = state!.audit[index];
                    final usado = item['loteUtilizado'] as Map<String, dynamic>?;
                    final correto = item['loteCorreto'] as Map<String, dynamic>?;
                    final user = item['utilizador'] as Map<String, dynamic>?;
                    final loteId = usado?['id']?.toString() ?? correto?['id']?.toString();
                    return DataRow(
                      onSelectChanged: loteId != null && loteId.isNotEmpty
                          ? (_) => _openLotDrawer(loteId)
                          : null,
                      cells: [
                      DataCell(Text(item['produtoNome']?.toString() ?? '—')),
                      DataCell(Text(usado?['numeroLote']?.toString() ?? '—')),
                      DataCell(Text(correto?['numeroLote']?.toString() ?? '—')),
                      DataCell(Text(user?['nome']?.toString() ?? '—')),
                      DataCell(Text(item['data']?.toString().substring(0, 10) ?? '—')),
                      DataCell(Text(item['situacao']?.toString() ?? '—')),
                      DataCell(Text(item['motivo']?.toString() ?? '—')),
                    ],
                    );
                  },
                ),
              ],
            ),
          ),
          MovimentacoesPagination(
            page: _tabIndex == 0 ? (state?.pageOverview ?? 1) : (state?.pageAudit ?? 1),
            pageSize: state?.pageSize ?? 20,
            hasMore: _tabIndex == 0
                ? (state?.hasMoreOverview ?? false)
                : (state?.hasMoreAudit ?? false),
            isBusy: asyncState.isLoading,
            onPrev: _tabIndex == 0
                ? ((state?.pageOverview ?? 1) > 1
                    ? () => controller.goToPageOverview((state?.pageOverview ?? 1) - 1)
                    : null)
                : ((state?.pageAudit ?? 1) > 1
                    ? () => controller.goToPageAudit((state?.pageAudit ?? 1) - 1)
                    : null),
            onNext: _tabIndex == 0
                ? (state?.hasMoreOverview == true
                    ? () => controller.goToPageOverview((state?.pageOverview ?? 1) + 1)
                    : null)
                : (state?.hasMoreAudit == true
                    ? () => controller.goToPageAudit((state?.pageAudit ?? 1) + 1)
                    : null),
            onPageSizeChanged: controller.setPageSize,
          ),
        ],
      ),
    );
  }

  Future<void> _openLotDrawer(String loteId) async {
    if (loteId.isEmpty) return;
    final padding = context.spacing.md;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.centerRight,
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: padding),
        backgroundColor: Colors.transparent,
        child: LotDetailDrawer(
          loteId: loteId,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  String _alertLabel(String? situacao) {
    switch (situacao) {
      case 'VIOLACAO_FEFO':
        return 'Violação operacional';
      case 'SEM_LOTE_FEFO':
        return 'Sem lote elegível';
      case 'CONFORME_FEFO':
      default:
        return 'Conforme';
    }
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notification_important_outlined, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
