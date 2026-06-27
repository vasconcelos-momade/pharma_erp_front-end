import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/loading/skeleton_loaders.dart';

class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key, this.kpiCount = 4});

  final int kpiCount;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: s.sm,
          runSpacing: s.sm,
          children: List.generate(
            kpiCount,
            (_) => SizedBox(
              width: 180,
              height: 88,
              child: SkeletonBox(height: 88, radius: context.pharmaTokens.radiusMd),
            ),
          ),
        ),
        SizedBox(height: s.lg),
        SkeletonBox(height: 220, radius: context.pharmaTokens.radiusMd),
        SizedBox(height: s.md),
        SkeletonBox(height: 220, radius: context.pharmaTokens.radiusMd),
      ],
    );
  }
}

class DashboardErrorState extends StatelessWidget {
  const DashboardErrorState({
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
        padding: EdgeInsets.all(s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: t.posDanger),
            SizedBox(height: s.md),
            Text(
              'Não foi possível carregar o painel',
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: s.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted),
            ),
            SizedBox(height: s.md),
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

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.title,
    this.subtitle = 'Não existem registos para os filtros seleccionados.',
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(s.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: t.textMuted),
            SizedBox(height: s.sm),
            Text(
              title,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: s.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
