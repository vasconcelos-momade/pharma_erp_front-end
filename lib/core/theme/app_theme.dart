import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'component_theme.dart';
import 'design_tokens.dart';
import 'typography.dart';

abstract final class AppTheme {
  AppTheme._();

  static ThemeData _enterpriseTheme({
    required PharmaTokens tokens,
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.bgPrimary,
      extensions: [tokens],
      textTheme: AppTypography.textThemeFor(brightness).apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bgSecondary,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: tokens.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          side: BorderSide(
            color: tokens.border.withValues(alpha: isDark ? 0.6 : 0.85),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          side: BorderSide(
            color: tokens.border.withValues(alpha: isDark ? 0.6 : 0.85),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusMd)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: PharmaComponentTheme.filled(tokens, scheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: PharmaComponentTheme.outlined(tokens, scheme),
      ),
      textButtonTheme: TextButtonThemeData(
        style: PharmaComponentTheme.text(tokens, scheme),
      ),
      iconButtonTheme: PharmaComponentTheme.iconButton(tokens, scheme),
      inputDecorationTheme: PharmaComponentTheme.input(tokens, scheme, isDark: isDark),
      dividerTheme: DividerThemeData(
        color: tokens.border.withValues(alpha: isDark ? 0.5 : 0.7),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData lightEnterprise({DensityTokens density = DensityTokens.comfortable}) {
    final tokens = PharmaTokens.enterpriseLight(density: density);
    final scheme = ColorScheme.light(
      surface: tokens.bgSecondary,
      onSurface: tokens.textPrimary,
      primary: tokens.brandGreen,
      onPrimary: Colors.white,
      secondary: tokens.brandBlue,
      onSecondary: Colors.white,
      error: tokens.posDanger,
      onError: Colors.white,
      outline: tokens.border,
      surfaceContainerHighest: tokens.card,
    );

    return _enterpriseTheme(
      tokens: tokens,
      brightness: Brightness.light,
      scheme: scheme,
    );
  }

  static ThemeData darkEnterprise({DensityTokens density = DensityTokens.comfortable}) {
    final tokens = PharmaTokens.enterpriseDark(density: density);
    final scheme = ColorScheme.dark(
      surface: tokens.bgSecondary,
      onSurface: tokens.textPrimary,
      primary: tokens.brandGreen,
      onPrimary: AppColors.ink950,
      secondary: tokens.brandBlue,
      onSecondary: AppColors.ink950,
      error: tokens.posDanger,
      onError: Colors.white,
      outline: tokens.border,
      surfaceContainerHighest: tokens.card,
    );

    return _enterpriseTheme(
      tokens: tokens,
      brightness: Brightness.dark,
      scheme: scheme,
    );
  }

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        textTheme: AppTypography.textThemeFor(Brightness.light),
        useMaterial3: true,
      );
}
