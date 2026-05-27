import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/ui/layout/pharma_screen_layout.dart';
import '../providers/invoice_list_provider.dart';

class InvoicesLoadingSkeleton extends StatelessWidget {
  const InvoicesLoadingSkeleton({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final isMobile = screen == PharmaScreenSize.mobile;
    final itemCount = isMobile ? 6 : 8;

    return ListView.separated(
      padding: embedded ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: s.lg),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) => _InvoiceSkeletonCard(),
      separatorBuilder: (context, index) => SizedBox(height: s.sm),
      itemCount: itemCount,
    );
  }
}

class _InvoiceSkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 140,
                height: 24,
                decoration: BoxDecoration(
                  color: t.bgSoft,
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 28,
                decoration: BoxDecoration(
                  color: t.bgSoft,
                  borderRadius: BorderRadius.circular(t.radius3xl),
                ),
              ),
            ],
          ),
          SizedBox(height: s.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: t.bgSoft,
                    borderRadius: BorderRadius.circular(t.radiusSm),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s.sm),
          Row(
            children: [
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: t.bgSoft,
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: t.bgSoft,
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InvoicesInfoBanner extends StatelessWidget {
  const InvoicesInfoBanner({super.key, required this.state});

  final InvoiceListState state;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    if (state.showingCachedData) {
      return Material(
        color: t.brandBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(s.md),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: t.brandBlue, size: t.iconMd),
              SizedBox(width: s.sm),
              Expanded(
                child: Text(
                  'A exibir dados em cache. Verifique a conexão.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: t.brandBlue,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.errorMessage != null && state.hasItems) {
      return Material(
        color: t.posWarning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(s.md),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: t.posWarning, size: t.iconMd),
              SizedBox(width: s.sm),
              Expanded(
                child: Text(
                  state.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: t.posWarning,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class InvoicesErrorState extends StatelessWidget {
  const InvoicesErrorState({
    super.key,
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
      child: Padding(
        padding: EdgeInsets.all(s.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: t.posDanger, size: 64),
            SizedBox(height: s.lg),
            Text(
              'Falha ao carregar faturas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: s.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: t.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: s.xl),
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

class InvoicesEmptyState extends StatelessWidget {
  const InvoicesEmptyState({super.key, this.onClearFilters});

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, color: t.textMuted, size: 64),
            SizedBox(height: s.lg),
            Text(
              onClearFilters != null ? 'Nenhuma fatura encontrada' : 'Ainda sem faturas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: s.sm),
            Text(
              onClearFilters != null
                  ? 'Tente ajustar os filtros ou a pesquisa.'
                  : 'As faturas emitidas aparecerão aqui.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: t.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onClearFilters != null) ...[
              SizedBox(height: s.xl),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_list_off_rounded),
                label: const Text('Limpar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
