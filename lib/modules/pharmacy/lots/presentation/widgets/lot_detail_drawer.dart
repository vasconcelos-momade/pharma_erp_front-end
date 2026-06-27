import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../inventory/data/datasources/inventory_remote_datasource.dart';

class LotDetailDrawer extends ConsumerStatefulWidget {
  const LotDetailDrawer({
    super.key,
    required this.loteId,
    required this.onClose,
  });

  final String loteId;
  final VoidCallback onClose;

  @override
  ConsumerState<LotDetailDrawer> createState() => _LotDetailDrawerState();
}

class _LotDetailDrawerState extends ConsumerState<LotDetailDrawer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _detail;
  List<Map<String, dynamic>> _movimentos = const [];
  List<Map<String, dynamic>> _reservas = const [];
  List<Map<String, dynamic>> _dispensacoes = const [];
  List<Map<String, dynamic>> _incineracoes = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ds = ref.read(inventoryRemoteDataSourceProvider);
    try {
      final detail = await ds.getLote(widget.loteId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      return;
    }

    final results = await Future.wait([
      _safeList(() => ds.listLoteMovimentos(widget.loteId)),
      _safeList(() => ds.listLoteReservas(widget.loteId)),
      _safeList(() => ds.listLoteDispensacoes(widget.loteId)),
      _safeList(() => ds.listLoteIncineracoes(widget.loteId)),
    ]);
    if (!mounted) return;
    setState(() {
      _movimentos = results[0];
      _reservas = results[1];
      _dispensacoes = results[2];
      _incineracoes = results[3];
      _loading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _safeList(
    Future<List<Map<String, dynamic>>> Function() loader,
  ) async {
    try {
      return await loader();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final detail = _detail;

    return Container(
      width: 620,
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: BorderRadius.circular(t.radiusXl),
        border: Border.all(color: t.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(s.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lote ${detail?['numeroLote'] ?? widget.loteId}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        detail?['produtoNome']?.toString() ?? 'Detalhe operacional do lote',
                        style: TextStyle(color: t.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Resumo'),
              Tab(text: 'Timeline'),
              Tab(text: 'Movimentos'),
              Tab(text: 'Reservas'),
              Tab(text: 'Dispensações'),
              Tab(text: 'Incinerações'),
              Tab(text: 'Sanitário'),
              Tab(text: 'Ações'),
            ],
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: EdgeInsets.all(s.md),
              child: Text(_error!, style: TextStyle(color: t.posDanger)),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ResumoTab(detail: detail),
                _TimelineTab(
                  items: _buildTimelineItems(),
                ),
                _CollectionTab(
                  empty: 'Sem movimentos registados.',
                  items: _movimentos,
                  builder: (item) => _titleSubtitle(
                    title:
                        '${item['tipoLabel'] ?? item['tipo']} • ${item['quantidade'] ?? 0}',
                    subtitle:
                        '${_formatDate(item['createdAt'])} • ${item['user']?['nome'] ?? 'Sistema'}',
                    trailing: item['origem']?.toString(),
                  ),
                ),
                _CollectionTab(
                  empty: 'Sem reservas activas.',
                  items: _reservas,
                  builder: (item) => _titleSubtitle(
                    title:
                        'Reserva ${item['fatura']?['numero'] ?? item['id']} • ${item['quantidade'] ?? 0}',
                    subtitle: 'Criada em ${_formatDate(item['createdAt'])}',
                    trailing: _formatDate(item['expiresAt']),
                  ),
                ),
                _CollectionTab(
                  empty: 'Sem dispensações associadas.',
                  items: _dispensacoes,
                  builder: (item) => _titleSubtitle(
                    title:
                        '${item['tipoDispensacao'] ?? 'Dispensação'} • ${item['quantidade'] ?? 0}',
                    subtitle:
                        '${_formatDate(item['createdAt'])} • ${item['user']?['nome'] ?? 'Sistema'}',
                  ),
                ),
                _CollectionTab(
                  empty: 'Sem incinerações registadas.',
                  items: _incineracoes,
                  builder: (item) => _titleSubtitle(
                    title:
                        'Auto ${item['incineracao']?['numeroAuto'] ?? item['id']} • ${item['quantidade'] ?? 0}',
                    subtitle:
                        'Incineração em ${_formatDate(item['incineracao']?['dataIncineracao'])}',
                    trailing: _formatDate(item['createdAt']),
                  ),
                ),
                _SanitarioTab(
                  detail: detail,
                  movimentos: _movimentos,
                  incineracoes: _incineracoes,
                ),
                _QuickActionsTab(detail: detail),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildTimelineItems() {
    final items = <Map<String, dynamic>>[
      ..._movimentos.map(
        (item) => {
          'tipo': 'Movimento',
          'titulo': item['tipoLabel'] ?? item['tipo'],
          'data': item['createdAt'],
          'detalhe': 'Quantidade ${item['quantidade'] ?? 0}',
        },
      ),
      ..._reservas.map(
        (item) => {
          'tipo': 'Reserva',
          'titulo': item['fatura']?['numero'] ?? 'Reserva',
          'data': item['createdAt'],
          'detalhe': 'Quantidade ${item['quantidade'] ?? 0}',
        },
      ),
      ..._dispensacoes.map(
        (item) => {
          'tipo': 'Dispensação',
          'titulo': item['tipoDispensacao'] ?? 'Dispensação',
          'data': item['createdAt'],
          'detalhe': 'Quantidade ${item['quantidade'] ?? 0}',
        },
      ),
      ..._incineracoes.map(
        (item) => {
          'tipo': 'Incineração',
          'titulo': item['incineracao']?['numeroAuto'] ?? 'Auto sanitário',
          'data': item['createdAt'],
          'detalhe': 'Quantidade ${item['quantidade'] ?? 0}',
        },
      ),
    ];
    items.sort(
      (a, b) => _dateOf(b['data']).compareTo(_dateOf(a['data'])),
    );
    return items;
  }

  DateTime _dateOf(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget _titleSubtitle({
    required String title,
    String? subtitle,
    String? trailing,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing == null ? null : Text(trailing),
    );
  }

  static String _formatDate(dynamic value) {
    if (value == null) return '—';
    final date = value is String ? DateTime.tryParse(value) : null;
    if (date == null) return value.toString();
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }
}

class _ResumoTab extends StatelessWidget {
  const _ResumoTab({required this.detail});

  final Map<String, dynamic>? detail;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final rows = <MapEntry<String, String?>>[
      MapEntry('Produto', detail?['produtoNome']?.toString()),
      MapEntry('Fornecedor', detail?['fornecedor']?['nome']?.toString()),
      MapEntry('Validade', LotDetailDrawerStateX.formatDate(detail?['dataValidade'])),
      MapEntry('Estado sanitário', detail?['estadoSanitario']?.toString()),
      MapEntry('Disponibilidade', detail?['disponibilidade']?.toString()),
      MapEntry('Qtd. inicial', detail?['quantidadeInicial']?.toString()),
      MapEntry('Qtd. actual', detail?['quantidadeAtual']?.toString()),
      MapEntry('Qtd. quarentena', detail?['quantidadeQuarentena']?.toString()),
      MapEntry('Qtd. incinerada', detail?['quantidadeIncinerada']?.toString()),
      MapEntry('Preço compra', detail?['precoCompra']?.toString()),
      MapEntry('Preço venda', detail?['precoVenda']?.toString()),
    ];
    return ListView.separated(
      padding: EdgeInsets.all(s.md),
      itemBuilder: (_, index) {
        final row = rows[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(
                row.key,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Text(row.value ?? '—')),
          ],
        );
      },
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemCount: rows.length,
    );
  }
}

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    if (items.isEmpty) {
      return const Center(child: Text('Sem histórico consolidado.'));
    }
    return ListView.separated(
      padding: EdgeInsets.all(s.md),
      itemBuilder: (_, index) {
        final item = items[index];
        return ListTile(
          leading: CircleAvatar(child: Text(item['tipo'].toString()[0])),
          title: Text(item['titulo']?.toString() ?? 'Evento'),
          subtitle: Text(item['detalhe']?.toString() ?? '—'),
          trailing: Text(LotDetailDrawerStateX.formatDate(item['data'])),
        );
      },
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemCount: items.length,
    );
  }
}

class _CollectionTab extends StatelessWidget {
  const _CollectionTab({
    required this.empty,
    required this.items,
    required this.builder,
  });

  final String empty;
  final List<Map<String, dynamic>> items;
  final Widget Function(Map<String, dynamic>) builder;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    if (items.isEmpty) {
      return Center(child: Text(empty));
    }
    return ListView.separated(
      padding: EdgeInsets.all(s.md),
      itemBuilder: (_, index) => builder(items[index]),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemCount: items.length,
    );
  }
}

class _SanitarioTab extends StatelessWidget {
  const _SanitarioTab({
    required this.detail,
    required this.movimentos,
    required this.incineracoes,
  });

  final Map<String, dynamic>? detail;
  final List<Map<String, dynamic>> movimentos;
  final List<Map<String, dynamic>> incineracoes;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final sanitarios = movimentos
        .where((item) => {'QUARENTENA', 'INCINERACAO'}.contains(item['tipo']))
        .toList(growable: false);
    return ListView(
      padding: EdgeInsets.all(s.md),
      children: [
        _StatusCard(
          title: 'Indicador sanitário',
          value: detail?['estadoSanitario']?.toString() ?? '—',
          color: detail?['estadoSanitario'] == 'VALIDO'
              ? t.brandGreen
              : t.posDanger,
        ),
        SizedBox(height: s.sm),
        _StatusCard(
          title: 'Quarentena',
          value: '${detail?['quantidadeQuarentena'] ?? 0}',
          color: Colors.orange,
        ),
        SizedBox(height: s.sm),
        _StatusCard(
          title: 'Incinerações',
          value: '${incineracoes.length}',
          color: t.posDanger,
        ),
        SizedBox(height: s.md),
        Text(
          'Movimentos sanitários',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: s.sm),
        if (sanitarios.isEmpty)
          const Text('Nenhum movimento sanitário crítico registado.')
        else
          ...sanitarios.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item['tipoLabel']?.toString() ?? item['tipo'].toString()),
              subtitle: Text(item['observacoes']?.toString() ?? 'Sem observações'),
              trailing: Text(LotDetailDrawerStateX.formatDate(item['createdAt'])),
            ),
          ),
      ],
    );
  }
}

class _QuickActionsTab extends StatelessWidget {
  const _QuickActionsTab({required this.detail});

  final Map<String, dynamic>? detail;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final actions = <String>[
      'Verificar conformidade sanitária do lote',
      'Confirmar reservas e dispensações pendentes',
      'Auditar FEFO do produto associado',
      'Rever histórico de incinerações e quarentena',
      'Actualizar stock e preços do lote',
    ];
    return ListView.separated(
      padding: EdgeInsets.all(s.md),
      itemBuilder: (_, index) => ListTile(
        leading: const Icon(Icons.bolt_outlined),
        title: Text(actions[index]),
        subtitle: Text(
          'Contexto actual: ${detail?['produtoNome'] ?? detail?['numeroLote'] ?? 'lote'}',
        ),
      ),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemCount: actions.length,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.health_and_safety_outlined, color: color),
        ],
      ),
    );
  }
}

extension LotDetailDrawerStateX on LotDetailDrawer {
  static String formatDate(dynamic value) => _LotDetailDrawerState._formatDate(value);
}
