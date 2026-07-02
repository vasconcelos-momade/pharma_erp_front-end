import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'component_theme.dart';
import 'design_tokens.dart';
import 'pharma_border_tokens.dart';
import 'pharma_color_tokens.dart';
import 'pharma_dashboard_tokens.dart';
import 'pharma_finance_tokens.dart';
import 'pharma_healthcare_tokens.dart';
import 'pharma_navigation_tokens.dart';
import 'pharma_radius_tokens.dart';
import 'typography.dart';
import 'dashboard_theme.dart';
import 'table_theme.dart';
import 'healthcare_theme.dart';
import 'navigation_theme.dart';

abstract final class AppTheme {
  AppTheme._();

  static ThemeData _enterpriseTheme({
    required PharmaTokens tokens,
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorTokens = PharmaColorTokens.fromLegacy(tokens: tokens, scheme: scheme);
    final radiusTokens = PharmaRadiusTokens.fromLegacy(tokens);
    final borderTokens = PharmaBorderTokens.fromLegacy(tokens);
    final navigationTokens =
        PharmaNavigationTokens.fromLegacy(tokens: tokens, scheme: scheme);
    final dashboardTokens = PharmaDashboardTokens.fromLegacy(tokens);
    final financeTokens = PharmaFinanceTokens.fromLegacy(tokens);
    final healthcareTokens = PharmaHealthcareTokens.fromLegacy(tokens);

    final dashboardTheme = DashboardTheme.fromLegacy(tokens);
    final tableTheme = TableTheme.fromLegacy(tokens);
    final specificHealthcareTheme = HealthcareTheme.fromLegacy(tokens);
    final specificNavigationTheme = NavigationThemeData.fromLegacy(tokens);

    final textTheme = AppTypography.textThemeFor(brightness).apply(
        bodyColor: tokens.textPrimary,
        displayColor: tokens.textPrimary,
      );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.bgPrimary,
      extensions: [
        tokens,
        colorTokens,
        radiusTokens,
        borderTokens,
        navigationTokens,
        dashboardTokens,
        financeTokens,
        healthcareTokens,
        dashboardTheme,
        tableTheme,
        specificHealthcareTheme,
        specificNavigationTheme,
      ],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bgSecondary,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.appBarTitle(textTheme).copyWith(
          color: tokens.textPrimary,
        ),
        toolbarTextStyle: textTheme.erpTabLabel.copyWith(color: tokens.textSecondary),
      ),
      chipTheme: PharmaComponentTheme.chip(tokens, scheme, isDark: isDark),
      tooltipTheme: PharmaComponentTheme.tooltip(tokens, scheme),
      snackBarTheme: PharmaComponentTheme.snackBar(tokens, scheme),
      scrollbarTheme: PharmaComponentTheme.scrollbar(tokens),
      cardTheme: PharmaComponentTheme.card(tokens, isDark: isDark),
      dialogTheme: PharmaComponentTheme.dialog(tokens, isDark: isDark),
      bottomSheetTheme: PharmaComponentTheme.bottomSheet(tokens),
      popupMenuTheme: PharmaComponentTheme.popupMenu(tokens),
      menuTheme: PharmaComponentTheme.menu(tokens),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: tokens.textPrimary),
        inputDecorationTheme: PharmaComponentTheme.input(tokens, scheme, isDark: isDark),
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
      checkboxTheme: PharmaComponentTheme.checkbox(scheme),
      switchTheme: PharmaComponentTheme.switchTheme(scheme),
      radioTheme: PharmaComponentTheme.radio(scheme),
      sliderTheme: PharmaComponentTheme.slider(scheme),
      dividerTheme: PharmaComponentTheme.divider(tokens, isDark: isDark),
      dataTableTheme: PharmaComponentTheme.dataTable(tokens),
      listTileTheme: PharmaComponentTheme.listTile(tokens),
      navigationRailTheme: PharmaComponentTheme.navigationRail(tokens, scheme),
      navigationDrawerTheme: PharmaComponentTheme.navigationDrawer(tokens, scheme, isDark: isDark),
      navigationBarTheme: PharmaComponentTheme.navigationBar(tokens, scheme, isDark: isDark),
      progressIndicatorTheme: PharmaComponentTheme.progressIndicator(scheme),
      tabBarTheme: PharmaComponentTheme.tabBar(tokens, scheme, isDark: isDark, textTheme: textTheme),
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

  static final Map<DensityLevel, ThemeData> _lightCache = {};
  static final Map<DensityLevel, ThemeData> _darkCache = {};

  static ThemeData lightEnterprise({DensityTokens density = DensityTokens.comfortable}) {
    return _lightCache.putIfAbsent(density.level, () {
      final tokens = PharmaTokens.enterpriseLight(density: density);
      final scheme = ColorScheme.light(
        surface: tokens.bgSecondary,
        onSurface: tokens.textPrimary,
        primary: tokens.brandGreen,
        onPrimary: Colors.white,
        secondary: tokens.brandGreenHover,
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
    });
  }

  static ThemeData darkEnterprise({DensityTokens density = DensityTokens.comfortable}) {
    return _darkCache.putIfAbsent(density.level, () {
      final tokens = PharmaTokens.enterpriseDark(density: density);
      final scheme = ColorScheme.dark(
        surface: tokens.bgSecondary,
        onSurface: tokens.textPrimary,
        primary: tokens.brandGreen,
        onPrimary: AppColors.ink950,
        secondary: tokens.brandGreenHover,
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
    });
  }

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        textTheme: AppTypography.textThemeFor(Brightness.light),
        useMaterial3: true,
      );
}
