import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class TableTheme extends ThemeExtension<TableTheme> {
  const TableTheme({
    required this.headerBackgroundColor,
    required this.headerTextStyle,
    required this.rowHeight,
    required this.dividerColor,
    required this.hoverColor,
    required this.selectedColor,
  });

  final Color headerBackgroundColor;
  final TextStyle headerTextStyle;
  final double rowHeight;
  final Color dividerColor;
  final Color hoverColor;
  final Color selectedColor;

  factory TableTheme.fromLegacy(PharmaTokens tokens) {
    return TableTheme(
      headerBackgroundColor: tokens.bgSecondary,
      headerTextStyle: TextStyle(
        color: tokens.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      rowHeight: 52,
      dividerColor: tokens.border,
      hoverColor: tokens.cardHover,
      selectedColor: tokens.brandBlue.withValues(alpha: 0.12),
    );
  }

  @override
  TableTheme copyWith({
    Color? headerBackgroundColor,
    TextStyle? headerTextStyle,
    double? rowHeight,
    Color? dividerColor,
    Color? hoverColor,
    Color? selectedColor,
  }) {
    return TableTheme(
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      rowHeight: rowHeight ?? this.rowHeight,
      dividerColor: dividerColor ?? this.dividerColor,
      hoverColor: hoverColor ?? this.hoverColor,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }

  @override
  TableTheme lerp(ThemeExtension<TableTheme>? other, double t) {
    if (other is! TableTheme) return this;
    return TableTheme(
      headerBackgroundColor: Color.lerp(headerBackgroundColor, other.headerBackgroundColor, t)!,
      headerTextStyle: TextStyle.lerp(headerTextStyle, other.headerTextStyle, t)!,
      rowHeight: lerpDouble(rowHeight, other.rowHeight, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      hoverColor: Color.lerp(hoverColor, other.hoverColor, t)!,
      selectedColor: Color.lerp(selectedColor, other.selectedColor, t)!,
    );
  }

  static double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }
}

extension TableThemeX on BuildContext {
  TableTheme get tableTheme =>
      Theme.of(this).extension<TableTheme>() ??
      TableTheme.fromLegacy(
        Theme.of(this).extension<PharmaTokens>() ?? PharmaTokens.enterpriseLight(),
      );
}
