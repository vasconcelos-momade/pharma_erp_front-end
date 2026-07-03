import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'breakpoints.dart';
import 'design_metrics.dart';

/// Larguras máximas por contexto de layout (conteúdo, formulários, diálogos).
@immutable
class WidthTokens extends ThemeExtension<WidthTokens> {
  const WidthTokens({
    required this.contentMax,
    required this.formMax,
    required this.authCardMax,
    required this.sideSheetMax,
    required this.dialogMobileInset,
    required this.dialogTabletFraction,
    required this.dialogDesktopFraction,
    required this.dialogContentCapFraction,
  });

  final double contentMax;
  final double formMax;
  final double authCardMax;
  final double sideSheetMax;
  final double dialogMobileInset;
  final double dialogTabletFraction;
  final double dialogDesktopFraction;
  final double dialogContentCapFraction;

  factory WidthTokens.standard() {
    return const WidthTokens(
      contentMax: DesignMetrics.contentMaxWidth,
      formMax: 640,
      authCardMax: 440,
      sideSheetMax: 560,
      dialogMobileInset: DesignMetrics.dialogMobileHorizontalInset,
      dialogTabletFraction: DesignMetrics.dialogWidthFractionTablet,
      dialogDesktopFraction: DesignMetrics.dialogWidthFractionDesktop,
      dialogContentCapFraction: DesignMetrics.dialogWidthCapContentFraction,
    );
  }

  /// Largura efectiva de diálogo conforme viewport.
  double dialogWidthFor(double viewportWidth) {
    if (viewportWidth < Breakpoints.mobile) {
      return viewportWidth - (dialogMobileInset * 2);
    }
    if (viewportWidth < Breakpoints.desktop) {
      return viewportWidth * dialogTabletFraction;
    }
    final capped = contentMax * dialogContentCapFraction;
    final fraction = viewportWidth * dialogDesktopFraction;
    return fraction < capped ? fraction : capped;
  }

  @override
  WidthTokens copyWith({
    double? contentMax,
    double? formMax,
    double? authCardMax,
    double? sideSheetMax,
    double? dialogMobileInset,
    double? dialogTabletFraction,
    double? dialogDesktopFraction,
    double? dialogContentCapFraction,
  }) {
    return WidthTokens(
      contentMax: contentMax ?? this.contentMax,
      formMax: formMax ?? this.formMax,
      authCardMax: authCardMax ?? this.authCardMax,
      sideSheetMax: sideSheetMax ?? this.sideSheetMax,
      dialogMobileInset: dialogMobileInset ?? this.dialogMobileInset,
      dialogTabletFraction: dialogTabletFraction ?? this.dialogTabletFraction,
      dialogDesktopFraction: dialogDesktopFraction ?? this.dialogDesktopFraction,
      dialogContentCapFraction:
          dialogContentCapFraction ?? this.dialogContentCapFraction,
    );
  }

  @override
  WidthTokens lerp(ThemeExtension<WidthTokens>? other, double t) {
    if (other is! WidthTokens) return this;
    return WidthTokens(
      contentMax: lerpDouble(contentMax, other.contentMax, t)!,
      formMax: lerpDouble(formMax, other.formMax, t)!,
      authCardMax: lerpDouble(authCardMax, other.authCardMax, t)!,
      sideSheetMax: lerpDouble(sideSheetMax, other.sideSheetMax, t)!,
      dialogMobileInset:
          lerpDouble(dialogMobileInset, other.dialogMobileInset, t)!,
      dialogTabletFraction:
          lerpDouble(dialogTabletFraction, other.dialogTabletFraction, t)!,
      dialogDesktopFraction:
          lerpDouble(dialogDesktopFraction, other.dialogDesktopFraction, t)!,
      dialogContentCapFraction: lerpDouble(
        dialogContentCapFraction,
        other.dialogContentCapFraction,
        t,
      )!,
    );
  }
}
