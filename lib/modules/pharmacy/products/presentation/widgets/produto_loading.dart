import 'package:flutter/material.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/widgets/loading/skeleton_loaders.dart';

class ProdutoLoading extends StatelessWidget {
  const ProdutoLoading({super.key, this.isDesktop = false});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.all(s.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(
            10,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: s.sm),
              child: const SkeletonBox(height: 48, width: double.infinity),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(s.md),
      itemCount: 8,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (_, _) => const SkeletonBox(height: 100, width: double.infinity),
    );
  }
}
