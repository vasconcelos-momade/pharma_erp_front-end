import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class DashboardTheme extends ThemeExtension<DashboardTheme> {
  const DashboardTheme({
    required this.cardPadding,
    required this.kpiSpacing,
    required this.chartHeight,
    required this.trendUpColor,
    required this.trendDownColor,
    required this.badgeRadius,
  });

  final EdgeInsets cardPadding;
  final double kpiSpacing;
  final double chartHeight;
  final Color trendUpColor;
  final Color trendDownColor;
  final double badgeRadius;

  factory DashboardTheme.fromLegacy(PharmaTokens tokens) {
    return DashboardTheme(
      cardPadding: tokens.density.cardPadding,
      kpiSpacing: tokens.density.md,
      chartHeight: 300,
      trendUpColor: tokens.brandGreen,
      trendDownColor: tokens.posDanger,
      badgeRadius: tokens.radiusMd,
    );
  }

  @override
  DashboardTheme copyWith({
    EdgeInsets? cardPadding,
    double? kpiSpacing,
    double? chartHeight,
    Color? trendUpColor,
    Color? trendDownColor,
    double? badgeRadius,
  }) {
    return DashboardTheme(
      cardPadding: cardPadding ?? this.cardPadding,
      kpiSpacing: kpiSpacing ?? this.kpiSpacing,
      chartHeight: chartHeight ?? this.chartHeight,
      trendUpColor: trendUpColor ?? this.trendUpColor,
      trendDownColor: trendDownColor ?? this.trendDownColor,
      badgeRadius: badgeRadius ?? this.badgeRadius,
    );
  }

  @override
  DashboardTheme lerp(ThemeExtension<DashboardTheme>? other, double t) {
    if (other is! DashboardTheme) return this;
    return DashboardTheme(
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t)!,
      kpiSpacing: lerpDouble(kpiSpacing, other.kpiSpacing, t)!,
      chartHeight: lerpDouble(chartHeight, other.chartHeight, t)!,
      trendUpColor: Color.lerp(trendUpColor, other.trendUpColor, t)!,
      trendDownColor: Color.lerp(trendDownColor, other.trendDownColor, t)!,
      badgeRadius: lerpDouble(badgeRadius, other.badgeRadius, t)!,
    );
  }

  static double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }
}

extension DashboardThemeX on BuildContext {
  DashboardTheme get dashboardTheme =>
      Theme.of(this).extension<DashboardTheme>() ??
      DashboardTheme.fromLegacy(
        Theme.of(this).extension<PharmaTokens>() ?? PharmaTokens.enterpriseLight(),
      );
}
