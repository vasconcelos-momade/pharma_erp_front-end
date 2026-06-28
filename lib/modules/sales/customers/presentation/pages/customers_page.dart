import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../core/utils/list_csv_exporter.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_list_provider.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../widgets/customer_detail_panel.dart';
import '../widgets/customer_form_dialog.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  late final TextEditingController _searchController;
  static final _currency = NumberFormat('#,##0.00', 'pt_MZ');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(customerListProvider).query.search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final state = ref.watch(customerListProvider);
    final notifier = ref.read(customerListProvider.notifier);
    final dash = state.dashboard;

    if (_searchController.text != state.query.search) {
      _searchController.value = TextEditingValue(
        text: state.query.search,
        selection: TextSelection.collapsed(offset: state.query.search.length),
      );
    }

    return EnterpriseModuleHub(
      title: 'Clientes & convénios',
      subtitle: 'CRM operacional, limites de crédito e convénios hospitalares.',
      tag: 'Terminal',
      actions: [
        OutlinedButton.icon(
          onPressed: state.items.isEmpty ? null : () => _exportCustomers(state),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Exportar CSV'),
        ),
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : notifier.refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
        FilledButton.icon(
          onPressed: state.isBusy ? null : () => _openCreateDialog(context),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Novo cliente'),
        ),
      ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              onChanged: notifier.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Nome, NUIT, telefone ou email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          DropdownButton<String?>(
            value: state.query.tipo,
            hint: const Text('Tipo'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos os tipos')),
              DropdownMenuItem(value: 'PACIENTE', child: Text('Paciente')),
              DropdownMenuItem(value: 'EMPRESA', child: Text('Empresa')),
              DropdownMenuItem(value: 'CONVENIO', child: Text('Convénio')),
            ],
            onChanged: state.isBusy ? null : notifier.setTipoFilter,
          ),
          FilterChip(
            label: const Text('Com crédito'),
            selected: state.query.comCredito == true,
            onSelected: state.isBusy
                ? null
                : (_) => notifier.setComCreditoFilter(
                    state.query.comCredito == true ? null : true,
                  ),
          ),
          if (state.query.hasFilters)
            TextButton.icon(
              onPressed: state.isBusy ? null : notifier.clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar'),
            ),
        ],
      ),
      kpis: [
        EnterpriseStatCard(
          title: 'Total clientes',
          value: '${dash.totalClientes}',
          icon: Icons.people_outline,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Novos este mês',
          value: '${dash.novosClientes}',
          icon: Icons.person_add_outlined,
          accent: StatCardAccent.positive,
        ),
        EnterpriseStatCard(
          title: 'Activos (90 dias)',
          value: '${dash.clientesAtivos}',
          icon: Icons.verified_outlined,
          accent: StatCardAccent.neutral,
        ),
        EnterpriseStatCard(
          title: 'Com saldo',
          value: '${dash.clientesComCredito}',
          icon: Icons.account_balance_wallet_outlined,
          accent: StatCardAccent.warning,
        ),
      ],
      child: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CustomerListState state,
    CustomerListController notifier,
  ) {
    if (state.viewState == CustomerViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == CustomerViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar clientes',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: notifier.refresh,
        icon: Icons.people_outline,
      );
    }
    if (state.viewState == CustomerViewState.empty) {
      return ModuleEmptyState(
        title: 'Nenhum cliente encontrado',
        subtitle: state.query.hasFilters
            ? 'Tenta limpar os filtros para ver mais resultados.'
            : 'Ainda não existem clientes registados.',
        onClearFilters: state.query.hasFilters ? notifier.clearFilters : null,
      );
    }

    final t = context.pharmaTokens;
    final s = context.spacing;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: Text(
              state.errorMessage!,
              style: TextStyle(color: t.posWarning, fontSize: 12),
            ),
          ),
        Expanded(
          child: EnterpriseDataTable(
            columns: [
              for (final label in [
                'Cliente',
                'Tipo',
                'NUIT',
                'Saldo',
                'Faturas',
                'Registo',
              ])
                DataColumn(
                  label: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: t.textMuted,
                    ),
                  ),
                ),
            ],
            rowCount: state.items.length,
            rowBuilder: (context, index) {
              final c = state.items[index];
              return DataRow(
                onSelectChanged: (_) => _openDetails(context, c),
                cells: [
                  DataCell(
                    Text(
                      c.nome,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _tipoLabel(c.tipo),
                      style: TextStyle(color: t.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(c.nuit ?? '—', style: TextStyle(color: t.textMuted)),
                  ),
                  DataCell(
                    Text(
                      '${_currency.format(c.saldoAtual)} MT',
                      style: TextStyle(
                        color: c.saldoAtual > 0 ? t.posWarning : t.brandGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${c.faturaCount}',
                      style: TextStyle(color: t.brandBlue),
                    ),
                  ),
                  DataCell(
                    Text(
                      dateFmt.format(c.createdAt),
                      style: TextStyle(color: t.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: s.md),
        MovimentacoesPagination(
          page: state.query.page,
          pageSize: state.query.pageSize,
          hasMore: state.hasMore,
          isBusy: state.isBusy,
          onPrev: state.query.page > 1
              ? () => notifier.goToPage(state.query.page - 1)
              : null,
          onNext: state.hasMore
              ? () => notifier.goToPage(state.query.page + 1)
              : null,
          onPageSizeChanged: notifier.setPageSize,
        ),
      ],
    );
  }

  String _tipoLabel(String tipo) => switch (tipo) {
    'EMPRESA' => 'Empresa',
    'CONVENIO' => 'Convénio',
    _ => 'Paciente',
  };

  Future<void> _openDetails(
    BuildContext context,
    CustomerSummary customer,
  ) async {
    final isMobile = PharmaScreenLayout.isMobile(context);

    Future<void> onEdit() async {
      final detail = await ref
          .read(customerRepositoryProvider)
          .getCustomer(customer.id);
      if (!context.mounted) return;
      final result = await showCustomerFormDialog(context, customer: detail);
      if (result == null || !context.mounted) return;
      try {
        await ref
            .read(customerListProvider.notifier)
            .updateCustomer(customer.id, result.toPayload());
        if (context.mounted) {
          PharmaFeedback.success(context, 'Cliente actualizado');
        }
      } on ApiFailure catch (e) {
        if (context.mounted) PharmaFeedback.error(context, e.message);
      }
    }

    Future<void> onDelete() async {
      final confirmed = await PharmaFeedback.confirm(
        context: context,
        title: 'Excluir cliente',
        message: 'Deseja excluir «${customer.nome}»?',
        confirmText: 'Excluir',
      );
      if (!context.mounted || confirmed != true) return;
      try {
        await ref
            .read(customerListProvider.notifier)
            .deleteCustomer(customer.id);
        if (context.mounted) {
          PharmaFeedback.success(context, 'Cliente excluído');
          Navigator.of(context).pop();
        }
      } on ApiFailure catch (e) {
        if (context.mounted) PharmaFeedback.error(context, e.message);
      }
    }

    if (isMobile) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (screenContext) => Scaffold(
            appBar: AppBar(title: Text(customer.nome)),
            body: CustomerDetailPanel(
              customerId: customer.id,
              onClose: () => Navigator.of(screenContext).pop(),
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final t = context.pharmaTokens;
        final s = context.spacing;
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: s.md),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 520,
            height: MediaQuery.sizeOf(context).height * 0.85,
            decoration: BoxDecoration(
              color: t.bgPrimary,
              borderRadius: BorderRadius.circular(t.radiusXl),
              border: Border.all(color: t.border.withValues(alpha: 0.55)),
            ),
            child: CustomerDetailPanel(
              customerId: customer.id,
              onClose: () => Navigator.of(dialogContext).pop(),
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final result = await showCustomerFormDialog(context);
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(customerListProvider.notifier)
          .createCustomer(result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Cliente criado com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _exportCustomers(CustomerListState state) async {
    final dateFmt = DateFormat('dd/MM/yyyy');
    await ListCsvExporter.export(
      fileName: 'clientes-pagina-${state.query.page}',
      headers: const [
        'Nome',
        'Tipo',
        'NUIT',
        'Telefone',
        'Email',
        'Saldo',
        'Limite crédito',
        'Faturas',
        'Registo',
      ],
      rows: state.items
          .map(
            (c) => [
              c.nome,
              c.tipo,
              c.nuit ?? '—',
              c.telefone ?? '—',
              c.email ?? '—',
              _currency.format(c.saldoAtual),
              c.limiteCredito != null
                  ? _currency.format(c.limiteCredito!)
                  : '—',
              '${c.faturaCount}',
              dateFmt.format(c.createdAt),
            ],
          )
          .toList(),
    );
  }
}
