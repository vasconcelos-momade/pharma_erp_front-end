import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import '../providers/movimentacao_provider.dart';
import 'movimentacoes_overview_cards.dart';
import 'movimentacoes_pagination.dart';
import 'movimentacoes_state_widgets.dart';
import 'movimentacoes_table.dart';
import 'movimentacoes_toolbar.dart';

class MovimentacoesBody extends ConsumerWidget {
  const MovimentacoesBody({
    super.key,
    required this.searchController,
    required this.listState,
  });

  final TextEditingController searchController;
  final MovimentacaoListState listState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (PharmaScreenLayout.isMobile(context)) {
      return _MovimentacoesMobileBody(
        searchController: searchController,
        listState: listState,
      );
    }

    final s = context.spacing;
    final query = listState.query;
    final notifier = ref.read(movimentacaoListProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MovimentacoesToolbar(
          searchController: searchController,
          state: listState,
        ),
        SizedBox(height: s.md),
        MovimentacoesOverviewCards(
          overview: listState.overview,
          hasFilters: query.hasFilters,
        ),
        if (listState.errorMessage != null) ...[
          SizedBox(height: s.md),
          MovimentacoesInfoBanner(message: listState.errorMessage!),
        ],
        SizedBox(height: s.md),
        Expanded(child: _MovimentacoesResultsPane(listState: listState)),
        SizedBox(height: s.md),
        MovimentacoesPagination(
          page: query.page,
          pageSize: query.pageSize,
          hasMore: listState.hasMore,
          isBusy: listState.isBusy,
          onPrev: query.page > 1 ? () => notifier.goToPage(query.page - 1) : null,
          onNext: listState.hasMore ? () => notifier.goToPage(query.page + 1) : null,
          onPageSizeChanged: notifier.setPageSize,
        ),
      ],
    );
  }
}

class _MovimentacoesMobileBody extends ConsumerWidget {
  const _MovimentacoesMobileBody({
    required this.searchController,
    required this.listState,
  });

  final TextEditingController searchController;
  final MovimentacaoListState listState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final query = listState.query;
    final notifier = ref.read(movimentacaoListProvider.notifier);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: MovimentacoesToolbar(
            searchController: searchController,
            state: listState,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: s.md)),
        SliverToBoxAdapter(
          child: MovimentacoesOverviewCards(
            overview: listState.overview,
            hasFilters: query.hasFilters,
          ),
        ),
        if (listState.errorMessage != null) ...[
          SliverToBoxAdapter(child: SizedBox(height: s.md)),
          SliverToBoxAdapter(
            child: MovimentacoesInfoBanner(message: listState.errorMessage!),
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: s.md)),
        SliverToBoxAdapter(
          child: _MovimentacoesResultsPane(
            listState: listState,
            embedded: true,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: s.md)),
        SliverToBoxAdapter(
          child: MovimentacoesPagination(
            page: query.page,
            pageSize: query.pageSize,
            hasMore: listState.hasMore,
            isBusy: listState.isBusy,
            onPrev:
                query.page > 1 ? () => notifier.goToPage(query.page - 1) : null,
            onNext:
                listState.hasMore ? () => notifier.goToPage(query.page + 1) : null,
            onPageSizeChanged: notifier.setPageSize,
          ),
        ),
      ],
    );
  }
}

class _MovimentacoesResultsPane extends ConsumerWidget {
  const _MovimentacoesResultsPane({
    required this.listState,
    this.embedded = false,
  });

  final MovimentacaoListState listState;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final notifier = ref.read(movimentacaoListProvider.notifier);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (listState.viewState) {
        MovimentacaoViewState.loading => MovimentacoesLoadingSkeleton(
            embedded: embedded,
          ),
        MovimentacaoViewState.updating => Stack(
            children: [
              MovimentacoesTable(items: listState.items),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(minHeight: s.xxs),
              ),
            ],
          ),
        MovimentacaoViewState.error => MovimentacoesErrorState(
            message:
                listState.errorMessage ?? 'Falha ao carregar movimentos.',
            onRetry: notifier.refresh,
          ),
        MovimentacaoViewState.empty => MovimentacoesEmptyState(
            onClearFilters: listState.query.hasFilters
                ? notifier.clearFilters
                : null,
          ),
        _ => MovimentacoesTable(items: listState.items),
      },
    );
  }
}
