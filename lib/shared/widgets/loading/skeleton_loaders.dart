import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';

/// Blocos skeleton para listagens e cartões.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.85),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, v, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: t.border.withValues(alpha: v),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(t.radiusMd),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 120, height: 12),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(width: double.infinity, height: 22),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: 200, height: 12),
        ],
      ),
    );
  }
}
