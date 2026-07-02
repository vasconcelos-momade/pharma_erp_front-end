import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../presentation/widgets/regulatory_report_exports.dart';
import '../../../regulatory/data/datasources/regulatory_remote_datasource.dart';
import '../../../lots/presentation/widgets/lot_actions_helper.dart';

class RegulatoryPage extends ConsumerStatefulWidget {
  const RegulatoryPage({super.key});

  @override
  ConsumerState<RegulatoryPage> createState() => _RegulatoryPageState();
}

class _RegulatoryPageState extends ConsumerState<RegulatoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;
  Timer? _refreshTimer;

  bool _loadingSanitario = true;
  bool _loadingReports = true;
  String? _sanitarioError;
  String? _reportsError;
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reports = <Map<String, dynamic>>[];
  int _page = 1;
  int _pageSize = 20;
  bool _hasMore = false;
  int _total = 0;
  String _search = '';
  String? _estado;
  String? _alertaTipo;
  int _reportsPage = 1;
  int _reportsPageSize = 10;
  bool _reportsHasMore = false;
  int _reportsTotal = 0;
  String? _reportTipo;

  RegulatoryRemoteDataSource get _ds =>
      ref.read(regulatoryRemoteDataSourceProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController = TextEditingController();
    _bootstrap();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _tabController.index == 0
          ? _loadSanitario(silent: true)
          : _loadReports(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadSanitario(), _loadReports()]);
  }

  Future<void> _loadSanitario({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loadingSanitario = true;
        _sanitarioError = null;
      });
    }
    try {
      final results = await Future.wait([
        _ds.sanitarioDashboard(search: _search.isEmpty ? null : _search),
        _ds.listSanitario(
          search: _search.isEmpty ? null : _search,
          estado: _estado,
          alertaTipo: _alertaTipo,
          page: _page,
          pageSize: _pageSize,
        ),
      ]);
      final page = results[1] as dynamic;
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _items = page.items.cast<Map<String, dynamic>>();
        _page = page.page as int;
        _pageSize = page.pageSize as int;
        _hasMore = page.hasMore as bool;
        _total = (page.totalCount as int?) ?? _items.length;
        _loadingSanitario = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSanitario = false;
        _sanitarioError = error.toString();
      });
    }
  }

  Future<void> _loadReports({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loadingReports = true;
        _reportsError = null;
      });
    }
    try {
      final page = await _ds.listSanitarioReports(
        tipo: _reportTipo,
        page: _reportsPage,
        pageSize: _reportsPageSize,
      );
      if (!mounted) return;
      setState(() {
        _reports = page.items;
        _reportsPage = page.page;
        _reportsPageSize = page.pageSize;
        _reportsHasMore = page.hasMore;
        _reportsTotal = page.totalCount ?? _reports.length;
        _loadingReports = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingReports = false;
        _reportsError = error.toString();
      });
    }
  }

  Map<String, dynamic> _sanitarioReportQuery() {
    return {
      if (_search.isNotEmpty) 'q': _search,
      if (_estado != null) 'estado': _estado,
      if (_alertaTipo != null) 'alertaTipo': _alertaTipo,
    };
  }

  Future<void> _openHistory(String loteId) async {
    await LotActionsHelper.showHistory(context, ref, loteId);
  }

  @override
  Widget build(BuildContext context) {
    final dash = _dashboard?['kpis'] as Map<String, dynamic>?;
    return EnterpriseModuleHub(
      title: 'Sanitário / Alertas',
      subtitle:
          'Validade, recall, quarentena, incineração, stock crítico e relatórios oficiais integrados.',
      tag: 'Regulatório',
      actions: [
        IconButton(
          onPressed: () =>
              _tabController.index == 0 ? _loadSanitario() : _loadReports(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      kpis: dash == null || _tabController.index == 1
          ? null
          : [
              EnterpriseStatCard(
                title: 'Expirados',
                value: '${dash['expirados'] ?? 0}',
                icon: Icons.warning_amber_outlined,
              ),
              EnterpriseStatCard(
                title: 'Próx. validade',
                value: '${dash['proximosValidade'] ?? 0}',
                icon: Icons.schedule_outlined,
              ),
              EnterpriseStatCard(
                title: 'Recall',
                value: '${dash['recall'] ?? 0}',
                icon: Icons.report_problem_outlined,
              ),
              EnterpriseStatCard(
                title: 'Quarentena',
                value: '${dash['quarentena'] ?? 0}',
                icon: Icons.health_and_safety_outlined,
              ),
              EnterpriseStatCard(
                title: 'Incinerações',
                value: '${dash['incineracoes'] ?? 0}',
                icon: Icons.local_fire_department_outlined,
              ),
              EnterpriseStatCard(
                title: 'Alertas',
                value: '${dash['alertasSanitarios'] ?? 0}',
                icon: Icons.notifications_active_outlined,
              ),
            ],
      filters: _tabController.index == 0
          ? _buildSanitarioFilters()
          : _buildReportsFilters(),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            tabs: const [
              Tab(text: 'Alertas & lotes'),
              Tab(text: 'Relatórios'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSanitarioTab(context),
                _buildReportsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSanitarioFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Produto, lote, barcode...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              setState(() {
                _search = value.trim();
                _page = 1;
              });
              _loadSanitario();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: _estado,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'EXPIRADO', child: Text('Expirado')),
              DropdownMenuItem(value: 'RECALL', child: Text('Recall')),
              DropdownMenuItem(value: 'QUARENTENA', child: Text('Quarentena')),
              DropdownMenuItem(value: 'BLOQUEADO', child: Text('Bloqueado')),
              DropdownMenuItem(value: 'CRITICO', child: Text('Crítico')),
            ],
            onChanged: (value) {
              setState(() {
                _estado = value;
                _page = 1;
              });
              _loadSanitario();
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            initialValue: _alertaTipo,
            decoration: const InputDecoration(
              labelText: 'Tipo de alerta',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(
                value: 'LOTE_EXPIRADO',
                child: Text('Lote expirado'),
              ),
              DropdownMenuItem(
                value: 'LOTE_A_EXPIRAR',
                child: Text('Lote a expirar'),
              ),
              DropdownMenuItem(
                value: 'ESTOQUE_BAIXO',
                child: Text('Stock baixo'),
              ),
              DropdownMenuItem(
                value: 'PRODUTO_ESGOTADO',
                child: Text('Esgotado'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _alertaTipo = value;
                _page = 1;
              });
              _loadSanitario();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportsFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 280,
          child: DropdownButtonFormField<String?>(
            initialValue: _reportTipo,
            decoration: const InputDecoration(
              labelText: 'Tipo de relatório',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(
                value: 'RELATORIO_EXPIRADOS',
                child: Text('Expirados'),
              ),
              DropdownMenuItem(
                value: 'RELATORIO_QUARENTENA',
                child: Text('Quarentena'),
              ),
              DropdownMenuItem(
                value: 'RELATORIO_INCINERACAO',
                child: Text('Incineração'),
              ),
              DropdownMenuItem(
                value: 'MAPA_MENSAL_PSICOTROPICOS',
                child: Text('Mapa psicotrópicos'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _reportTipo = value;
                _reportsPage = 1;
              });
              _loadReports();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSanitarioTab(BuildContext context) {
    final t = context.pharmaTokens;
    return Column(
      children: [
        if (_loadingSanitario) const LinearProgressIndicator(),
        if (_sanitarioError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(_sanitarioError!, style: TextStyle(color: t.posDanger)),
          ),
        Expanded(
          child: _items.isEmpty && !_loadingSanitario
              ? const Center(
                  child: Text('Sem resultados para os filtros selecionados.'),
                )
              : EnterpriseDataTable(
                  columns: const [
                    DataColumn(label: Text('PRODUTO')),
                    DataColumn(label: Text('LOTE')),
                    DataColumn(label: Text('VALIDADE')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ALERTA')),
                    DataColumn(label: Text('STOCK')),
                  ],
                  rowCount: _items.length,
                  rowBuilder: (context, index) {
                    final item = _items[index];
                    return DataRow(
                      onSelectChanged: (_) =>
                          _openHistory(item['id'].toString()),
                      cells: [
                        DataCell(
                          Text(item['produto']?['nome']?.toString() ?? '—'),
                        ),
                        DataCell(Text(item['numeroLote']?.toString() ?? '—')),
                        DataCell(
                          Text(
                            item['dataValidade']?.toString().substring(0, 10) ??
                                '—',
                          ),
                        ),
                        DataCell(
                          _SanitaryBadge(label: item['status']?.toString()),
                        ),
                        DataCell(
                          Text(item['latestAlert']?['tipo']?.toString() ?? '—'),
                        ),
                        DataCell(Text('${item['quantidadeAtual'] ?? 0}')),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        MovimentacoesPagination(
          page: _page,
          pageSize: _pageSize,
          hasMore: _hasMore,
          isBusy: _loadingSanitario,
          onPrev: _page > 1
              ? () {
                  setState(() => _page -= 1);
                  _loadSanitario();
                }
              : null,
          onNext: _hasMore
              ? () {
                  setState(() => _page += 1);
                  _loadSanitario();
                }
              : null,
          onPageSizeChanged: (value) {
            setState(() {
              _pageSize = value;
              _page = 1;
            });
            _loadSanitario();
          },
        ),
        Text(
          'Total: $_total lote(s)',
          style: TextStyle(color: t.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildReportsTab(BuildContext context) {
    final t = context.pharmaTokens;
    return Column(
      children: [
        if (_loadingReports) const LinearProgressIndicator(),
        if (_reportsError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(_reportsError!, style: TextStyle(color: t.posDanger)),
          ),
        Expanded(
          child: _reports.isEmpty && !_loadingReports
              ? const Center(
                  child: Text('Sem resultados para os filtros selecionados.'),
                )
              : EnterpriseDataTable(
                  columns: const [
                    DataColumn(label: Text('TIPO')),
                    DataColumn(label: Text('PERÍODO')),
                    DataColumn(label: Text('ARQUIVO')),
                    DataColumn(label: Text('DATA')),
                  ],
                  rowCount: _reports.length,
                  rowBuilder: (context, index) {
                    final item = _reports[index];
                    return DataRow(
                      cells: [
                        DataCell(Text(item['tipo']?.toString() ?? '—')),
                        DataCell(Text(item['periodo']?.toString() ?? '—')),
                        DataCell(Text(item['arquivoUrl']?.toString() ?? '—')),
                        DataCell(
                          Text(
                            item['createdAt']?.toString().substring(0, 10) ??
                                '—',
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        MovimentacoesPagination(
          page: _reportsPage,
          pageSize: _reportsPageSize,
          hasMore: _reportsHasMore,
          isBusy: _loadingReports,
          onPrev: _reportsPage > 1
              ? () {
                  setState(() => _reportsPage -= 1);
                  _loadReports();
                }
              : null,
          onNext: _reportsHasMore
              ? () {
                  setState(() => _reportsPage += 1);
                  _loadReports();
                }
              : null,
          onPageSizeChanged: (value) {
            setState(() {
              _reportsPageSize = value;
              _reportsPage = 1;
            });
            _loadReports();
          },
        ),
        Text(
          'Total: $_reportsTotal relatório(s)',
          style: TextStyle(color: t.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _SanitaryBadge extends StatelessWidget {
  const _SanitaryBadge({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final value = label ?? '—';
    final color = switch (value) {
      'EXPIRADO' => t.posDanger,
      'RECALL' => Colors.deepOrange,
      'QUARENTENA' => t.posWarning,
      'BLOQUEADO' => Colors.amber.shade800,
      'CRITICO' => Colors.redAccent,
      _ => t.brandGreen,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
