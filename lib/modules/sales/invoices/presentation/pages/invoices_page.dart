import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/pharma_snackbar.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../domain/entities/invoice_summary.dart';
import '../providers/invoice_action_provider.dart';
import '../providers/invoice_detail_provider.dart';
import '../providers/invoice_list_provider.dart';

String _formatMoney(num value) {
  final amount = value.toDouble();
  final hasDecimals = amount != amount.truncateToDouble();
  return '${amount.toStringAsFixed(hasDecimals ? 2 : 0)} MT';
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${_formatDate(value)} $hour:$minute';
}

class SalesInvoicesPage extends ConsumerStatefulWidget {
  const SalesInvoicesPage({super.key});

  @override
  ConsumerState<SalesInvoicesPage> createState() => _SalesInvoicesPageState();
}

class _SalesInvoicesPageState extends ConsumerState<SalesInvoicesPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(invoiceListProvider).query.search;
    _searchController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    ref.listen<InvoiceActionState>(invoiceActionProvider, (previous, next) {
      if (!mounted || previous == next) {
        return;
      }
      final previousSubmitting = previous?.isSubmitting ?? false;
      if (previousSubmitting && !next.isSubmitting && next.errorMessage == null) {
        PharmaSnackbar.showSuccess(context, 'Fatura cancelada com sucesso.');
      }
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        PharmaSnackbar.showError(context, next.errorMessage!);
      }
    });

    final listState = ref.watch(invoiceListProvider);
    final detailState = ref.watch(invoiceDetailProvider);
    final query = listState.query;

    if (_searchController.text != query.search) {
      _searchController.value = TextEditingValue(
        text: query.search,
        selection: TextSelection.collapsed(offset: query.search.length),
      );
    }

    final totalInvoices = listState.items.length;
    final cancelled = listState.items.where((invoice) => invoice.isCancelled).length;
    final paid = listState.items.where((invoice) => invoice.isPaid).length;
    final pending = listState.items.where((invoice) => invoice.isPending).length;
    final isMobile = PharmaScreenLayout.isMobile(context);

    return EnterpriseModuleHub(
      title: 'Faturas de venda',
      subtitle:
          'Histórico operacional do POS com pesquisa, filtros rápidos, cache em memória e cancelamento seguro.',
      tag: 'Vendas',
      actions: [
        OutlinedButton.icon(
          onPressed: listState.isBusy
              ? null
              : () => ref.read(invoiceListProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      child: isMobile
          ? _InvoicesMobileContent(
              searchController: _searchController,
              listState: listState,
              detailState: detailState,
              totalInvoices: totalInvoices,
              paid: paid,
              pending: pending,
              cancelled: cancelled,
              onView: _openDetails,
              onCancel: _confirmCancelInvoice,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InvoicesToolbarV2(
                  searchController: _searchController,
                  state: listState,
                ),
                SizedBox(height: s.md),
                _InvoicesKpiGrid(
                  totalInvoices: totalInvoices,
                  paid: paid,
                  pending: pending,
                  cancelled: cancelled,
                  hasFilters: query.hasFilters,
                ),
                SizedBox(height: s.md),
                if (listState.showingCachedData || listState.errorMessage != null)
                  _InvoicesInfoBanner(state: listState),
                SizedBox(height: s.md),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: switch (listState.viewState) {
                      InvoiceViewState.loading => const _InvoicesLoadingSkeleton(),
                      InvoiceViewState.updating => Stack(
                          children: [
                            _InvoicesResults(
                              invoices: listState.items,
                              onView: _openDetails,
                              onCancel: _confirmCancelInvoice,
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              child: LinearProgressIndicator(minHeight: s.xxs),
                            ),
                          ],
                        ),
                      InvoiceViewState.error => _InvoicesErrorState(
                          message: listState.errorMessage ?? 'Falha ao carregar faturas.',
                          onRetry: () => ref.read(invoiceListProvider.notifier).refresh(),
                        ),
                      InvoiceViewState.empty => _InvoicesEmptyState(
                          onClearFilters: query.hasFilters
                              ? () => ref.read(invoiceListProvider.notifier).clearFilters()
                              : null,
                        ),
                      _ => _InvoicesResults(
                          invoices: listState.items,
                          onView: _openDetails,
                          onCancel: _confirmCancelInvoice,
                        ),
                    },
                  ),
                ),
                SizedBox(height: s.md),
                _InvoicePagination(
                  page: query.page,
                  pageSize: query.pageSize,
                  hasMore: listState.hasMore,
                  isBusy: listState.isBusy,
                  onPrev: query.page > 1
                      ? () => ref.read(invoiceListProvider.notifier).goToPage(query.page - 1)
                      : null,
                  onNext: listState.hasMore
                      ? () => ref.read(invoiceListProvider.notifier).goToPage(query.page + 1)
                      : null,
                  onPageSizeChanged: (value) =>
                      ref.read(invoiceListProvider.notifier).setPageSize(value),
                ),
                if (detailState.hasSelection) const SizedBox.shrink(),
              ],
            ),
    );
  }

  Future<void> _openDetails(InvoiceSummary invoice) async {
    ref.read(invoiceDetailProvider.notifier).open(invoice);
    final isMobile = PharmaScreenLayout.isMobile(context);

    if (isMobile) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (screenContext) => _InvoiceDetailScreen(
            invoice: invoice,
            onCancel: invoice.isCancelled
                ? null
                : () {
                    Navigator.of(screenContext).pop();
                    _confirmCancelInvoice(invoice);
                  },
          ),
        ),
      );
      ref.read(invoiceDetailProvider.notifier).close();
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final t = context.pharmaTokens;
        final s = context.spacing;
        return Dialog(
          alignment: Alignment.centerRight,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: s.md),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 520,
            decoration: BoxDecoration(
              color: t.bgPrimary,
              borderRadius: BorderRadius.circular(t.radiusXl),
              border: Border.all(color: t.border.withValues(alpha: 0.55)),
            ),
            child: _InvoiceDetailPanel(
              invoice: invoice,
              onClose: () => Navigator.of(dialogContext).pop(),
              onCancel: invoice.isCancelled
                  ? null
                  : () {
                      Navigator.of(dialogContext).pop();
                      _confirmCancelInvoice(invoice);
                    },
            ),
          ),
        );
      },
    );
    ref.read(invoiceDetailProvider.notifier).close();
  }

  Future<void> _confirmCancelInvoice(InvoiceSummary invoice) async {
    if (invoice.isCancelled) {
      return;
    }

    final result = await showDialog<_CancelInvoicePayload>(
      context: context,
      builder: (dialogContext) => _CancelInvoiceDialog(invoice: invoice),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      await ref.read(invoiceActionProvider.notifier).cancelInvoice(
            invoiceId: invoice.id,
            motivo: result.motivo,
            observacoes: result.observacoes,
          );
    } catch (_) {
      // A mensagem já é tratada pelo listener do provider.
    }
  }
}

class _InvoicesToolbarV2 extends ConsumerWidget {
  const _InvoicesToolbarV2({
    required this.searchController,
    required this.state,
  });

  final TextEditingController searchController;
  final InvoiceListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final query = state.query;
    final notifier = ref.read(invoiceListProvider.notifier);

    final searchField = TextField(
      controller: searchController,
      onChanged: notifier.onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Pesquisar nº da fatura, cliente ou terminal',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: t.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
        ),
        isDense: true,
      ),
    );

    final chips = <Widget>[
      for (final filter in InvoiceQuickFilter.values.where((f) => f != InvoiceQuickFilter.none))
        Padding(
          padding: EdgeInsets.only(right: s.sm),
          child: FilterChip(
            selected: query.quickFilter == filter,
            label: Text(_quickFilterLabel(filter)),
            onSelected: (_) => notifier.setQuickFilter(filter),
          ),
        ),
      if (query.hasFilters)
        Padding(
          padding: EdgeInsets.only(right: s.sm),
          child: TextButton.icon(
            onPressed: notifier.clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpar'),
          ),
        ),
    ];

    if (screen == PharmaScreenSize.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          SizedBox(height: s.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: searchField,
          ),
        ),
        SizedBox(width: s.md),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 0,
              runSpacing: s.sm,
              children: chips,
            ),
          ),
        ),
      ],
    );
  }

  String _quickFilterLabel(InvoiceQuickFilter filter) {
    return switch (filter) {
      InvoiceQuickFilter.today => 'Hoje',
      InvoiceQuickFilter.week => 'Semana',
      InvoiceQuickFilter.month => 'Mês',
      InvoiceQuickFilter.cancelled => 'Canceladas',
      InvoiceQuickFilter.paid => 'Pagas',
      InvoiceQuickFilter.pending => 'Pendentes',
      InvoiceQuickFilter.none => 'Todas',
    };
  }
}

class _InvoicesMobileContent extends ConsumerWidget {
  const _InvoicesMobileContent({
    required this.searchController,
    required this.listState,
    required this.detailState,
    required this.totalInvoices,
    required this.paid,
    required this.pending,
    required this.cancelled,
    required this.onView,
    required this.onCancel,
  });

  final TextEditingController searchController;
  final InvoiceListState listState;
  final InvoiceDetailState detailState;
  final int totalInvoices;
  final int paid;
  final int pending;
  final int cancelled;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final query = listState.query;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _InvoicesToolbarV2(
            searchController: searchController,
            state: listState,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: s.md)),
        SliverToBoxAdapter(
          child: _InvoicesKpiGrid(
            totalInvoices: totalInvoices,
            paid: paid,
            pending: pending,
            cancelled: cancelled,
            hasFilters: query.hasFilters,
          ),
        ),
        if (listState.showingCachedData || listState.errorMessage != null) ...[
          SliverToBoxAdapter(child: SizedBox(height: s.md)),
          SliverToBoxAdapter(child: _InvoicesInfoBanner(state: listState)),
        ],
        SliverToBoxAdapter(child: SizedBox(height: s.md)),
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: switch (listState.viewState) {
              InvoiceViewState.loading => const _InvoicesLoadingSkeleton(embedded: true),
              InvoiceViewState.updating => Stack(
                  children: [
                    _InvoicesResults(
                      invoices: listState.items,
                      onView: onView,
                      onCancel: onCancel,
                      embedded: true,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: LinearProgressIndicator(minHeight: s.xxs),
                    ),
                  ],
                ),
              InvoiceViewState.error => _InvoicesErrorState(
                  message: listState.errorMessage ?? 'Falha ao carregar faturas.',
                  onRetry: () => ref.read(invoiceListProvider.notifier).refresh(),
                ),
              InvoiceViewState.empty => _InvoicesEmptyState(
                  onClearFilters: query.hasFilters
                      ? () => ref.read(invoiceListProvider.notifier).clearFilters()
                      : null,
                ),
              _ => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _InvoicesResults(
                      invoices: listState.items,
                      onView: onView,
                      onCancel: onCancel,
                      embedded: true,
                    ),
                    SizedBox(height: s.md),
                    _InvoicePagination(
                      page: query.page,
                      pageSize: query.pageSize,
                      hasMore: listState.hasMore,
                      isBusy: listState.isBusy,
                      onPrev: query.page > 1
                          ? () => ref.read(invoiceListProvider.notifier).goToPage(query.page - 1)
                          : null,
                      onNext: listState.hasMore
                          ? () => ref.read(invoiceListProvider.notifier).goToPage(query.page + 1)
                          : null,
                      onPageSizeChanged: (value) =>
                          ref.read(invoiceListProvider.notifier).setPageSize(value),
                    ),
                    if (detailState.hasSelection) const SizedBox.shrink(),
                  ],
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _InvoicesKpiGrid extends StatelessWidget {
  const _InvoicesKpiGrid({
    required this.totalInvoices,
    required this.paid,
    required this.pending,
    required this.cancelled,
    required this.hasFilters,
  });

  final int totalInvoices;
  final int paid;
  final int pending;
  final int cancelled;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final screen = context.pharmaScreen;
    return LayoutBuilder(
      builder: (context, c) {
        final cross = switch (screen) {
          PharmaScreenSize.mobile => 1,
          PharmaScreenSize.tablet => 2,
          PharmaScreenSize.desktop => 4,
        };
        final aspect = switch (screen) {
          PharmaScreenSize.mobile => 2.35,
          PharmaScreenSize.tablet => 1.7,
          PharmaScreenSize.desktop => 1.45,
        };
        return GridView.count(
          crossAxisCount: cross,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: screen == PharmaScreenSize.mobile ? 10 : s.md,
          mainAxisSpacing: screen == PharmaScreenSize.mobile ? 10 : s.md,
          childAspectRatio: aspect,
          children: [
            EnterpriseStatCard(
              title: 'Visíveis',
              value: '$totalInvoices',
              subtitle: hasFilters ? 'Com filtros activos' : 'Lista actual',
              icon: Icons.receipt_long_outlined,
              accent: StatCardAccent.info,
            ),
            EnterpriseStatCard(
              title: 'Pagas',
              value: '$paid',
              subtitle: 'Liquidadas no POS',
              icon: Icons.check_circle_outline_rounded,
              accent: StatCardAccent.positive,
            ),
            EnterpriseStatCard(
              title: 'Pendentes',
              value: '$pending',
              subtitle: 'Emitidas/parciais',
              icon: Icons.timelapse_rounded,
              accent: StatCardAccent.warning,
            ),
            EnterpriseStatCard(
              title: 'Canceladas',
              value: '$cancelled',
              subtitle: 'Com reversão aplicada',
              icon: Icons.block_rounded,
              accent: StatCardAccent.danger,
            ),
          ],
        );
      },
    );
  }
}

class _InvoicesResults extends StatelessWidget {
  const _InvoicesResults({
    required this.invoices,
    required this.onView,
    required this.onCancel,
    this.embedded = false,
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCards = PharmaScreenLayout.isMobile(context) || constraints.maxWidth < 860;
        if (useCards) {
          return _InvoiceCardList(
            invoices: invoices,
            onView: onView,
            onCancel: onCancel,
            embedded: embedded,
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: _InvoiceDesktopTable(
            invoices: invoices,
            onView: onView,
            onCancel: onCancel,
          ),
        );
      },
    );
  }
}

class _InvoicesLoadingSkeleton extends StatelessWidget {
  const _InvoicesLoadingSkeleton({this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final isMobile = screen == PharmaScreenSize.mobile;
    final itemCount = isMobile ? 6 : 8;

    return ListView.separated(
      shrinkWrap: embedded,
      physics: embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        final height = isMobile ? 142.0 : 58.0;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: t.card.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(t.radiusXl),
            border: Border.all(color: t.border.withValues(alpha: 0.35)),
          ),
        );
      },
    );
  }
}

class _InvoicesInfoBanner extends StatelessWidget {
  const _InvoicesInfoBanner({required this.state});

  final InvoiceListState state;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isWarning = state.errorMessage != null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: isWarning
            ? t.posWarning.withValues(alpha: 0.12)
            : t.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(
          color: isWarning
              ? t.posWarning.withValues(alpha: 0.35)
              : t.brandBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWarning ? Icons.cloud_off_rounded : Icons.history_toggle_off_rounded,
            color: isWarning ? t.posWarning : t.brandBlue,
          ),
          SizedBox(width: s.sm),
          Expanded(
            child: Text(
              state.errorMessage != null
                  ? 'A mostrar cache em memória. ${state.errorMessage}'
                  : 'A mostrar cache instantânea enquanto a API sincroniza.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesErrorState extends StatelessWidget {
  const _InvoicesErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 42, color: t.posDanger),
            SizedBox(height: s.md),
            Text(
              'Falha ao carregar faturas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: s.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: t.textMuted,
                  ),
            ),
            SizedBox(height: s.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoicesEmptyState extends StatelessWidget {
  const _InvoicesEmptyState({this.onClearFilters});

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: t.textMuted),
          SizedBox(height: s.md),
          Text(
            'Nenhuma fatura encontrada',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: s.sm),
          Text(
            onClearFilters != null
                ? 'Tenta limpar os filtros para ver mais resultados.'
                : 'Ainda não existem faturas disponíveis para esta unidade.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: t.textMuted,
                ),
          ),
          if (onClearFilters != null) ...[
            SizedBox(height: s.lg),
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceCardList extends StatelessWidget {
  const _InvoiceCardList({
    required this.invoices,
    required this.onView,
    required this.onCancel,
    this.embedded = false,
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return ListView.separated(
      shrinkWrap: embedded,
      physics: embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: invoices.length,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(t.radiusXl),
              border: Border.all(color: t.border.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(t.radiusXl),
            onTap: () => onView(invoice),
            child: Padding(
              padding: EdgeInsets.all(s.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.numero,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      _InvoiceStatusBadge(status: invoice.estado),
                    ],
                  ),
                  SizedBox(height: s.xs),
                  Text(
                    invoice.cliente?.nome ?? 'Consumidor final',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: t.textSecondary,
                        ),
                  ),
                  SizedBox(height: s.sm),
                  Wrap(
                    spacing: s.sm,
                    runSpacing: s.xs,
                    children: [
                      _MetaChip(label: _formatDateTime(invoice.createdAt)),
                      _MetaChip(label: _formatMoney(invoice.total)),
                      _MetaChip(
                        label: invoice.terminal?.codigo ?? invoice.terminal?.nome ?? 'Sem terminal',
                      ),
                    ],
                  ),
                  SizedBox(height: s.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onView(invoice),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Ver'),
                      ),
                      SizedBox(height: s.sm),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Imprimir'),
                      ),
                      SizedBox(height: s.sm),
                      FilledButton.icon(
                        onPressed: invoice.isCancelled ? null : () => onCancel(invoice),
                        icon: const Icon(Icons.block_rounded),
                        label: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }
}

class _InvoiceDesktopTable extends StatelessWidget {
  const _InvoiceDesktopTable({
    required this.invoices,
    required this.onView,
    required this.onCancel,
  });

  final List<InvoiceSummary> invoices;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusXl),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: LayoutBuilder(
        builder: (context, c) {
          final dense = c.maxWidth < 1100;
          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: c.maxWidth),
                child: DataTable(
                  headingRowColor:
                      WidgetStatePropertyAll(t.bgSecondary.withValues(alpha: 0.92)),
                  dataRowMinHeight: dense ? 48 : 54,
                  dataRowMaxHeight: dense ? 54 : 62,
                  horizontalMargin: dense ? s.md : s.lg,
                  columnSpacing: dense ? s.lg : s.xl,
                  columns: const [
                    DataColumn(label: Text('Nº')),
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Data')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: invoices.map((invoice) {
                    return DataRow(
                      cells: [
                        DataCell(Text(invoice.numero)),
                        DataCell(Text(invoice.cliente?.nome ?? 'Consumidor final')),
                        DataCell(Text(_formatDateTime(invoice.createdAt))),
                        DataCell(
                          Text(
                            _formatMoney(invoice.total),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: t.brandGreen,
                                ),
                          ),
                        ),
                        DataCell(_InvoiceStatusBadge(status: invoice.estado)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Ver',
                                onPressed: () => onView(invoice),
                                icon: const Icon(Icons.visibility_outlined),
                              ),
                              IconButton(
                                tooltip: invoice.isCancelled ? 'Já cancelada' : 'Cancelar',
                                onPressed: invoice.isCancelled ? null : () => onCancel(invoice),
                                icon: const Icon(Icons.block_rounded),
                              ),
                              IconButton(
                                tooltip: 'Impressão (em breve)',
                                onPressed: null,
                                icon: const Icon(Icons.print_outlined),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(growable: false),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceStatusBadge extends StatelessWidget {
  const _InvoiceStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final normalized = status.toUpperCase();
    final (fg, bg) = switch (normalized) {
      'PAGA' => (t.brandGreen, t.brandGreen.withValues(alpha: 0.12)),
      'ANULADA' => (t.posDanger, t.posDanger.withValues(alpha: 0.12)),
      'PARCIAL' => (t.posWarning, t.posWarning.withValues(alpha: 0.14)),
      _ => (t.brandBlue, t.brandBlue.withValues(alpha: 0.12)),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs + 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(t.radius3xl),
      ),
      child: Text(
        normalized,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs + 2),
      decoration: BoxDecoration(
        color: t.bgSecondary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(t.radius3xl),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: t.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InvoicePagination extends StatelessWidget {
  const _InvoicePagination({
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.isBusy,
    this.onPrev,
    this.onNext,
    required this.onPageSizeChanged,
  });

  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isBusy;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final pageSizeOptions = const [10, 25, 50, 100];

    if (screen == PharmaScreenSize.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Página $page',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              DropdownButton<int>(
                value: pageSizeOptions.contains(pageSize) ? pageSize : pageSizeOptions.first,
                items: pageSizeOptions
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value itens'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isBusy ? null : (value) => value != null ? onPageSizeChanged(value) : null,
              ),
            ],
          ),
          SizedBox(height: s.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onPrev,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Anterior'),
                ),
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy || !hasMore ? null : onNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Próxima'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          'Página $page',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(width: s.lg),
        Text(
          hasMore ? 'Mais resultados disponíveis' : 'Fim da lista',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.pharmaTokens.textMuted,
              ),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: pageSizeOptions.contains(pageSize) ? pageSize : pageSizeOptions.first,
          items: pageSizeOptions
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value / página'),
                ),
              )
              .toList(growable: false),
          onChanged: isBusy ? null : (value) => value != null ? onPageSizeChanged(value) : null,
        ),
        SizedBox(width: s.md),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Anterior'),
        ),
        SizedBox(width: s.sm),
        FilledButton.icon(
          onPressed: isBusy || !hasMore ? null : onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Próxima'),
        ),
      ],
    );
  }
}

class _InvoiceDetailScreen extends ConsumerWidget {
  const _InvoiceDetailScreen({
    required this.invoice,
    this.onCancel,
  });

  final InvoiceSummary invoice;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final actionState = ref.watch(invoiceActionProvider);
    final isCancelling =
        actionState.isSubmitting && actionState.activeInvoiceId == invoice.id;

    return Scaffold(
      backgroundColor: t.bgPrimary,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(invoice.numero),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.cliente?.nome ?? 'Consumidor final',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: t.textMuted,
                            ),
                      ),
                      SizedBox(height: s.md),
                      _InvoiceStatusBadge(status: invoice.estado),
                      SizedBox(height: s.lg),
                      _DetailSection(
                        title: 'Dados da fatura',
                        children: [
                          _DetailRow(label: 'Número', value: invoice.numero),
                          _DetailRow(label: 'Série', value: invoice.serie ?? '-'),
                          _DetailRow(label: 'Data', value: _formatDateTime(invoice.createdAt)),
                          _DetailRow(
                            label: 'Cancelada em',
                            value: _formatDateTime(invoice.cancelledAt),
                          ),
                          _DetailRow(
                            label: 'Método de pagamento',
                            value: invoice.tipoPagamento ?? '-',
                          ),
                          _DetailRow(
                            label: 'Terminal',
                            value: invoice.terminal?.codigo ?? invoice.terminal?.nome ?? '-',
                          ),
                          _DetailRow(
                            label: 'Operador',
                            value: invoice.user?.name ?? '-',
                          ),
                        ],
                      ),
                      SizedBox(height: s.lg),
                      _DetailSection(
                        title: 'Totais',
                        children: [
                          _DetailRow(label: 'Subtotal', value: _formatMoney(invoice.subtotal)),
                          _DetailRow(label: 'IVA', value: _formatMoney(invoice.ivaTotal)),
                          _DetailRow(label: 'Total', value: _formatMoney(invoice.total)),
                        ],
                      ),
                      SizedBox(height: s.lg),
                      _DetailSection(
                        title: 'Itens e pagamentos',
                        children: [
                          _DetailRow(label: 'Linhas registadas', value: '${invoice.itemCount}'),
                          _DetailRow(label: 'Pagamentos', value: '${invoice.paymentCount}'),
                          const _DetailHint(
                            text:
                                'Detalhe completo, lotes FEFO, PDF e reimpressão ficam preparados no layout e dependem do endpoint de detalhe/impressão.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: s.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Reimprimir'),
                  ),
                  SizedBox(height: s.sm),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                  SizedBox(height: s.sm),
                  FilledButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: isCancelling
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_rounded),
                    label: const Text('Cancelar fatura'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceDetailPanel extends ConsumerWidget {
  const _InvoiceDetailPanel({
    required this.invoice,
    required this.onClose,
    this.onCancel,
  });

  final InvoiceSummary invoice;
  final VoidCallback onClose;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final isMobile = PharmaScreenLayout.isMobile(context);
    final actionState = ref.watch(invoiceActionProvider);
    final isCancelling =
        actionState.isSubmitting && actionState.activeInvoiceId == invoice.id;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.numero,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: t.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              SizedBox(height: s.xs),
                              Text(
                                invoice.cliente?.nome ?? 'Consumidor final',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: t.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    SizedBox(height: s.md),
                    _InvoiceStatusBadge(status: invoice.estado),
                    SizedBox(height: s.lg),
                    _DetailSection(
                      title: 'Dados da fatura',
                      children: [
                        _DetailRow(label: 'Número', value: invoice.numero),
                        _DetailRow(label: 'Série', value: invoice.serie ?? '-'),
                        _DetailRow(label: 'Data', value: _formatDateTime(invoice.createdAt)),
                        _DetailRow(
                          label: 'Cancelada em',
                          value: _formatDateTime(invoice.cancelledAt),
                        ),
                        _DetailRow(
                          label: 'Método de pagamento',
                          value: invoice.tipoPagamento ?? '-',
                        ),
                        _DetailRow(
                          label: 'Terminal',
                          value: invoice.terminal?.codigo ?? invoice.terminal?.nome ?? '-',
                        ),
                        _DetailRow(
                          label: 'Operador',
                          value: invoice.user?.name ?? '-',
                        ),
                      ],
                    ),
                    SizedBox(height: s.lg),
                    _DetailSection(
                      title: 'Totais',
                      children: [
                        _DetailRow(label: 'Subtotal', value: _formatMoney(invoice.subtotal)),
                        _DetailRow(label: 'IVA', value: _formatMoney(invoice.ivaTotal)),
                        _DetailRow(label: 'Total', value: _formatMoney(invoice.total)),
                      ],
                    ),
                    SizedBox(height: s.lg),
                    _DetailSection(
                      title: 'Itens e pagamentos',
                      children: [
                        _DetailRow(label: 'Linhas registadas', value: '${invoice.itemCount}'),
                        _DetailRow(label: 'Pagamentos', value: '${invoice.paymentCount}'),
                        const _DetailHint(
                          text:
                              'Detalhe completo, lotes FEFO, PDF e reimpressão ficam preparados no layout e dependem do endpoint de detalhe/impressão.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: s.lg),
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Reimprimir'),
                  ),
                  SizedBox(height: s.sm),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                  SizedBox(height: s.sm),
                  FilledButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: isCancelling
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_rounded),
                    label: const Text('Cancelar fatura'),
                  ),
                ],
              )
            else
              Wrap(
                spacing: s.sm,
                runSpacing: s.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Reimprimir'),
                  ),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                  FilledButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: isCancelling
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.block_rounded),
                    label: const Text('Cancelar fatura'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: s.sm),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: s.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: t.textMuted,
                  ),
            ),
          ),
          SizedBox(width: s.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHint extends StatelessWidget {
  const _DetailHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Padding(
      padding: EdgeInsets.only(top: s.xs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: t.textMuted,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}

class _CancelInvoiceDialog extends StatefulWidget {
  const _CancelInvoiceDialog({required this.invoice});

  final InvoiceSummary invoice;

  @override
  State<_CancelInvoiceDialog> createState() => _CancelInvoiceDialogState();
}

class _CancelInvoiceDialogState extends State<_CancelInvoiceDialog> {
  late final TextEditingController _reasonController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 600;

    return Dialog(
      backgroundColor: t.bgPrimary,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 24 : 40,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: media.size.height * 0.82,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: s.lg,
            right: s.lg,
            top: s.lg,
            bottom: media.viewInsets.bottom + s.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancelar ${widget.invoice.numero}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: s.md),
                Text(
                  'Esta ação deve refletir a reversão no backend. Informe o motivo do cancelamento.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: t.textMuted,
                      ),
                ),
                SizedBox(height: s.lg),
                TextField(
                  controller: _reasonController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Ex.: erro no caixa',
                  ),
                ),
                SizedBox(height: s.md),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    hintText: 'Opcional',
                  ),
                ),
                SizedBox(height: s.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ),
                    SizedBox(width: s.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          final motivo = _reasonController.text.trim();
                          if (motivo.isEmpty) {
                            PharmaSnackbar.showError(
                              context,
                              'Informe o motivo do cancelamento.',
                            );
                            return;
                          }
                          Navigator.of(context).pop(
                            _CancelInvoicePayload(
                              motivo: motivo,
                              observacoes: _notesController.text.trim().isEmpty
                                  ? null
                                  : _notesController.text.trim(),
                            ),
                          );
                        },
                        child: const Text('Confirmar cancelamento'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelInvoicePayload {
  const _CancelInvoicePayload({
    required this.motivo,
    this.observacoes,
  });

  final String motivo;
  final String? observacoes;
}
