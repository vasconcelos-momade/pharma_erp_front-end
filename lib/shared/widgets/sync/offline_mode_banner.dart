import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/spacing.dart';

class OfflineModeBanner extends StatelessWidget {
  const OfflineModeBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Material(
      color: t.posWarning.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(t.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.posWarning.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: t.posWarning, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.erpCaption.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
