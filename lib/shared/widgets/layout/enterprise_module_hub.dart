import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../responsive/pharma_screen_layout.dart';
import '../cards/enterprise_stat_card.dart';

/// Hub de módulo com grelha KPI adaptativa e cabeçalho denso em mobile/tablet.
class EnterpriseModuleHub extends StatelessWidget {
  const EnterpriseModuleHub({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    this.actions,
    this.kpis,
    required this.child,
    this.filters,
  });

  final String title;
  final String subtitle;
  final String tag;
  final List<Widget>? actions;
  final List<EnterpriseStatCard>? kpis;
  final Widget child;
  /// Filtros opcionais (ex.: chips) — em mobile ficam numa linha com scroll horizontal.
  final Widget? filters;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final size = context.pharmaScreen;
    final titleStyle = switch (size) {
      PharmaScreenSize.mobile => Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      PharmaScreenSize.tablet => Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      PharmaScreenSize.desktop => Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: t.brandBlue,
                          letterSpacing: size == PharmaScreenSize.mobile ? 1.4 : 2.2,
                          fontSize: size == PharmaScreenSize.mobile ? 9 : null,
                        ),
                  ),
                  SizedBox(height: size == PharmaScreenSize.mobile ? 2 : AppSpacing.xs),
                  Text(
                    title,
                    maxLines: size == PharmaScreenSize.mobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle?.copyWith(color: t.textPrimary),
                  ),
                  SizedBox(height: size == PharmaScreenSize.mobile ? 4 : AppSpacing.sm),
                  Text(
                    subtitle,
                    maxLines: size == PharmaScreenSize.mobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                          fontSize: size == PharmaScreenSize.mobile ? 12 : null,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              size == PharmaScreenSize.mobile
                  ? IconButton(
                      onPressed: () => _showQuickActions(context, actions!),
                      icon: const Icon(Icons.more_horiz_rounded),
                      tooltip: 'Acções',
                    )
                  : Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions!),
          ],
        ),
        if (filters != null) ...[
          SizedBox(height: size == PharmaScreenSize.mobile ? AppSpacing.sm : AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: filters!,
          ),
        ],
        if (kpis != null && kpis!.isNotEmpty) ...[
          SizedBox(height: size == PharmaScreenSize.mobile ? AppSpacing.md : AppSpacing.xl),
          LayoutBuilder(
            builder: (context, c) {
              final cross = PharmaScreenLayout.kpiCrossAxisCount(c.maxWidth);
              final aspect = PharmaScreenLayout.kpiChildAspectRatio(size);
              return GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: size == PharmaScreenSize.mobile ? 8 : AppSpacing.md,
                mainAxisSpacing: size == PharmaScreenSize.mobile ? 8 : AppSpacing.md,
                childAspectRatio: aspect,
                children: kpis!,
              );
            },
          ),
        ],
        SizedBox(height: size == PharmaScreenSize.mobile ? AppSpacing.md : AppSpacing.xxl),
        Expanded(child: child),
      ],
    );
  }

  static void _showQuickActions(BuildContext context, List<Widget> actions) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: actions,
          ),
        ),
      ),
    );
  }
}
