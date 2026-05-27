import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';

enum PharmaDialogBreakpoint {
  mobile,
  tablet,
  desktop,
}

PharmaDialogBreakpoint pharmaDialogBreakpointForWidth(double width) {
  if (width < DesignMetrics.breakpointMobile) {
    return PharmaDialogBreakpoint.mobile;
  }
  if (width < DesignMetrics.breakpointTablet) {
    return PharmaDialogBreakpoint.tablet;
  }
  return PharmaDialogBreakpoint.desktop;
}

/// Dialog responsivo com padding explícito e largura fluida (sem [Flexible] em [Column.min]).
class PharmaResponsiveDialog extends StatelessWidget {
  const PharmaResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.scrollable = true,
  });

  final Widget title;
  final Widget content;
  final List<Widget>? actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final screenSize = MediaQuery.sizeOf(context);
    final breakpoint = pharmaDialogBreakpointForWidth(screenSize.width);
    final isMobile = breakpoint == PharmaDialogBreakpoint.mobile;

    final horizontalInset = isMobile
        ? DesignMetrics.dialogMobileHorizontalInset
        : s.lg;

    final availableWidth = screenSize.width - (horizontalInset * 2);
    final maxDialogWidth = _maxDialogWidth(
      breakpoint: breakpoint,
      availableWidth: availableWidth,
      screenWidth: screenSize.width,
      contentMaxWidth: t.contentMaxWidth,
    );

    final maxDialogHeight = screenSize.height * (isMobile ? 0.92 : 0.88);

    final titlePadding = EdgeInsets.fromLTRB(
      isMobile ? s.lg : s.xl,
      isMobile ? s.md : s.lg,
      isMobile ? s.lg : s.xl,
      s.sm,
    );
    final contentPadding = EdgeInsets.fromLTRB(
      isMobile ? s.lg : s.xl,
      s.sm,
      isMobile ? s.lg : s.xl,
      actions == null || actions!.isEmpty ? s.lg : s.md,
    );
    final actionsPadding = EdgeInsets.fromLTRB(
      isMobile ? s.lg : s.xl,
      s.xs,
      isMobile ? s.lg : s.xl,
      isMobile ? s.md : s.lg,
    );

    final Widget bodySection;
    if (scrollable) {
      bodySection = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight * 0.65),
        child: SingleChildScrollView(
          padding: contentPadding,
          child: content,
        ),
      );
    } else {
      bodySection = Padding(
        padding: contentPadding,
        child: content,
      );
    }

    return Dialog(
      backgroundColor: t.card,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: isMobile ? s.lg : s.xxl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog(t)),
        side: BorderSide(
          color: t.border.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.6 : 0.85,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.dialog(t)),
            boxShadow: AppShadows.dialog(context),
          ),
          child: Material(
            color: t.card,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: titlePadding,
                  child: DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                    child: title,
                  ),
                ),
                bodySection,
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: actionsPadding,
                    child: PharmaResponsiveDialogActions(
                      breakpoint: breakpoint,
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _maxDialogWidth({
    required PharmaDialogBreakpoint breakpoint,
    required double availableWidth,
    required double screenWidth,
    required double contentMaxWidth,
  }) {
    final safeAvailable = availableWidth > 0 ? availableWidth : screenWidth;
    switch (breakpoint) {
      case PharmaDialogBreakpoint.mobile:
        return safeAvailable;
      case PharmaDialogBreakpoint.tablet:
        final fractionCap = screenWidth * DesignMetrics.dialogWidthFractionTablet;
        return fractionCap < safeAvailable ? fractionCap : safeAvailable;
      case PharmaDialogBreakpoint.desktop:
        final fractionCap = screenWidth * DesignMetrics.dialogWidthFractionDesktop;
        final contentCap = contentMaxWidth * DesignMetrics.dialogWidthCapContentFraction;
        final cap = fractionCap < contentCap ? fractionCap : contentCap;
        return cap < safeAvailable ? cap : safeAvailable;
    }
  }
}

/// Ações: [Row] com [Expanded] no mobile; [Wrap] no tablet/desktop.
class PharmaResponsiveDialogActions extends StatelessWidget {
  const PharmaResponsiveDialogActions({
    super.key,
    required this.children,
    required this.breakpoint,
  });

  final List<Widget> children;
  final PharmaDialogBreakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final minH = context.pharmaTokens.minTouchTarget;
    final isMobile = breakpoint == PharmaDialogBreakpoint.mobile;

    if (isMobile) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: s.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 0,
                      minHeight: minH,
                    ),
                    child: children[i],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Wrap(
      spacing: s.sm,
      runSpacing: s.sm,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final child in children)
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: child,
          ),
      ],
    );
  }
}

Future<T?> showPharmaResponsiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}
