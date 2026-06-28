import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer.dart';

class CustomerDetailPanel extends ConsumerStatefulWidget {
  const CustomerDetailPanel({
    super.key,
    required this.customerId,
    required this.onClose,
    this.onEdit,
    this.onDelete,
  });

  final String customerId;
  final VoidCallback onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  ConsumerState<CustomerDetailPanel> createState() =>
      _CustomerDetailPanelState();
}

class _CustomerDetailPanelState extends ConsumerState<CustomerDetailPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  var _loading = true;
  String? _error;
  CustomerDetail? _detail;
  List<CustomerFaturaRef> _faturas = [];
  List<CustomerContaReceber> _contas = [];
  List<CustomerReceitaRef> _receitas = [];
  List<CustomerAuditEntry> _audit = [];

  static final _currency = NumberFormat('#,##0.00', 'pt_MZ');
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
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

    try {
      final repo = ref.read(customerRepositoryProvider);
      final detail = await repo.getCustomer(widget.customerId);
      final faturas = await repo.listCustomerFaturas(widget.customerId);
      final contas = await repo.listCustomerContasReceber(widget.customerId);
      final receitas = await repo.listCustomerReceitas(widget.customerId);
      final audit = await repo.listCustomerAudit(widget.customerId);

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _faturas = faturas.items;
        _contas = contas.items;
        _receitas = receitas.items;
        _audit = audit.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.sm, s.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _detail?.nome ?? 'Cliente',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              if (widget.onEdit != null)
                IconButton(
                  tooltip: 'Editar',
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (widget.onDelete != null)
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline, color: t.posDanger),
                ),
              IconButton(
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
            Tab(text: 'Dados'),
            Tab(text: 'Faturas'),
            Tab(text: 'Contas'),
            Tab(text: 'Receitas'),
            Tab(text: 'Auditoria'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: t.posDanger)))
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _buildDadosTab(t, s),
                        _buildListTab(
                          t,
                          _faturas.isEmpty
                              ? 'Sem faturas'
                              : _faturas
                                  .map(
                                    (f) =>
                                        '${f.numero} • ${_currency.format(f.total)} MT • ${f.estado}',
                                  )
                                  .join('\n'),
                        ),
                        _buildListTab(
                          t,
                          _contas.isEmpty
                              ? 'Sem contas a receber'
                              : _contas
                                  .map(
                                    (c) =>
                                        '${c.status} • saldo ${_currency.format(c.saldo)} MT',
                                  )
                                  .join('\n'),
                        ),
                        _buildListTab(
                          t,
                          _receitas.isEmpty
                              ? 'Sem receitas'
                              : _receitas
                                  .map(
                                    (r) =>
                                        '${r.numeroReceita ?? '—'} • ${_dateFmt.format(r.dataReceita)}',
                                  )
                                  .join('\n'),
                        ),
                        _buildListTab(
                          t,
                          _audit.isEmpty
                              ? 'Sem registos de auditoria'
                              : _audit
                                  .map(
                                    (a) =>
                                        '${a.action} • ${a.userNome ?? 'Sistema'} • ${_dateTimeFmt.format(a.createdAt)}',
                                  )
                                  .join('\n'),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildDadosTab(PharmaTokens t, DensityTokens s) {
    final d = _detail!;
    return ListView(
      padding: EdgeInsets.all(s.lg),
      children: [
        _infoRow(t, 'Tipo', _tipoLabel(d.tipo)),
        _infoRow(t, 'NUIT', d.nuit ?? '—'),
        _infoRow(t, 'Telefone', d.telefone ?? '—'),
        _infoRow(t, 'Email', d.email ?? '—'),
        _infoRow(t, 'Documento', d.documento ?? '—'),
        _infoRow(t, 'Endereço', d.endereco ?? '—'),
        _infoRow(t, 'Empresa', d.empresaNome ?? '—'),
        _infoRow(t, 'Saldo', '${_currency.format(d.saldoAtual)} MT'),
        _infoRow(
          t,
          'Limite crédito',
          d.limiteCredito != null
              ? '${_currency.format(d.limiteCredito!)} MT'
              : '—',
        ),
        _infoRow(t, 'Faturas', '${d.faturaCount}'),
        _infoRow(t, 'Contas', '${d.contaReceberCount}'),
        _infoRow(t, 'Receitas', '${d.receitaCount}'),
        _infoRow(t, 'Registo', _dateFmt.format(d.createdAt)),
      ],
    );
  }

  Widget _buildListTab(PharmaTokens t, String content) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing.lg),
      child: Text(
        content,
        style: TextStyle(color: t.textSecondary, height: 1.6),
      ),
    );
  }

  Widget _infoRow(PharmaTokens t, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: t.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tipoLabel(String tipo) => switch (tipo) {
        'EMPRESA' => 'Empresa',
        'CONVENIO' => 'Convénio',
        _ => 'Paciente',
      };
}
