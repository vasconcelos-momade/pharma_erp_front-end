import 'package:flutter/material.dart';

import '../../../../core/theme/design_metrics.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';

/// Canal interno de notificações rápidas (SnackBar).
abstract final class SnackbarChannel {
  SnackbarChannel._();

  static void showSuccess(BuildContext context, String message) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      iconColor: scheme.onPrimary,
      backgroundColor: t.brandGreen,
      foregroundColor: scheme.onPrimary,
    );
  }

  static void showError(BuildContext context, String message) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: scheme.onError,
      backgroundColor: t.posDanger,
      foregroundColor: scheme.onError,
    );
  }

  static void showInfo(BuildContext context, String message) {
    final t = context.pharmaTokens;
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: t.posInfo,
    );
  }

  static void showWarning(BuildContext context, String message) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: scheme.onPrimary,
      backgroundColor: t.posWarning,
      foregroundColor: scheme.onPrimary,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    Color? iconColor,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    final resolvedBg = backgroundColor ?? scheme.inverseSurface;
    final resolvedFg = foregroundColor ??
        (backgroundColor != null ? scheme.onPrimary : t.textPrimary);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: resolvedBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusMd),
          side: BorderSide(color: t.border.withValues(alpha: 0.6)),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? t.brandGreen,
              size: DesignMetrics.feedbackIconSize,
            ),
            SizedBox(width: t.density.md),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                      color: resolvedFg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
