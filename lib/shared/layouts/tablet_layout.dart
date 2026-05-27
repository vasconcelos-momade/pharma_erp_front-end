import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';

/// Envolvimento touch-first para tablets: mais respiro, alvos largos, hierarquia clara.
class TabletLayout extends StatelessWidget {
  const TabletLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = MediaQuery.paddingOf(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: EdgeInsets.fromLTRB(
          p.left + AppSpacing.xl,
          p.top + AppSpacing.md,
          p.right + AppSpacing.xl,
          p.bottom + AppSpacing.md,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: child,
      ),
    );
  }
}
