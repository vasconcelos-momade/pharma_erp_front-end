import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/spacing_tokens.dart';

Future<T?> showPharmaModalSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  String? subtitle,
}) {
  final t =
      Theme.of(context).extension<PharmaTokens>() ??
      PharmaTokens.enterpriseDark();
  final s = t.density;
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: scheme.surface.withValues(alpha: 0),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          margin: EdgeInsets.all(s.lg),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.border.withValues(alpha: 0.65)),
            boxShadow: ctx.shadows.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(s.xxl, s.lg, s.lg, s.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(ctx).textTheme.erpCardTitle,
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: s.xs),
                            Text(
                              subtitle,
                              style: Theme.of(ctx).textTheme.erpBodySecondary.copyWith(
                                    color: t.textMuted,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: SpacingTokens.pagePadding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
