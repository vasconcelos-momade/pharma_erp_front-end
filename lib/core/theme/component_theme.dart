import 'package:flutter/material.dart';

import 'design_tokens.dart';

abstract final class PharmaComponentTheme {
  PharmaComponentTheme._();

  static ButtonStyle _baseButtonStyle(PharmaTokens tokens) {
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(tokens.minTouchTarget, tokens.minTouchTarget),
      ),
      padding: WidgetStateProperty.all(tokens.density.buttonPadding),
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
    );
  }

  static ButtonStyle filled(PharmaTokens tokens, ColorScheme scheme) {
    return _baseButtonStyle(tokens).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        return scheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.onPrimary;
      }),
    );
  }

  static ButtonStyle outlined(PharmaTokens tokens, ColorScheme scheme) {
    return _baseButtonStyle(tokens).copyWith(
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.primary;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: scheme.onSurface.withValues(alpha: 0.12));
        }
        return BorderSide(color: scheme.outline);
      }),
    );
  }

  static ButtonStyle text(PharmaTokens tokens, ColorScheme scheme) {
    return _baseButtonStyle(tokens).copyWith(
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.primary;
      }),
      padding: WidgetStateProperty.all(tokens.density.buttonPadding),
    );
  }

  static IconButtonThemeData iconButton(PharmaTokens tokens, ColorScheme scheme) {
    return IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(
          Size.square(tokens.minTouchTarget),
        ),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          return scheme.onSurface;
        }),
      ),
    );
  }

  static InputDecorationTheme input(PharmaTokens tokens, ColorScheme scheme, {required bool isDark}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      borderSide: BorderSide(color: tokens.border),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? tokens.card.withValues(alpha: 0.35) : tokens.card,
      constraints: BoxConstraints(minHeight: tokens.minTouchTarget),
      contentPadding: tokens.density.inputPadding,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(
          color: isDark
              ? tokens.brandGreen.withValues(alpha: 0.55)
              : tokens.brandBlue.withValues(alpha: 0.65),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.posDanger),
      ),
      labelStyle: TextStyle(color: tokens.textSecondary),
      hintStyle: TextStyle(color: tokens.textMuted),
    );
  }

  static ChipThemeData chip(PharmaTokens tokens, ColorScheme scheme, {required bool isDark}) {
    return ChipThemeData(
      backgroundColor: tokens.card,
      selectedColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
      disabledColor: scheme.onSurface.withValues(alpha: 0.08),
      labelStyle: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w600),
      secondaryLabelStyle: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.w600),
      side: BorderSide(color: tokens.border.withValues(alpha: isDark ? 0.55 : 0.75)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      padding: EdgeInsets.symmetric(horizontal: tokens.density.sm, vertical: tokens.density.xs),
    );
  }

  static TooltipThemeData tooltip(PharmaTokens tokens, ColorScheme scheme) {
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      textStyle: TextStyle(color: scheme.onInverseSurface),
      preferBelow: true,
    );
  }

  static SnackBarThemeData snackBar(PharmaTokens tokens, ColorScheme scheme) {
    return SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusMd)),
    );
  }

  static ScrollbarThemeData scrollbar(PharmaTokens tokens) {
    return ScrollbarThemeData(
      radius: Radius.circular(tokens.radiusMd),
      thickness: WidgetStateProperty.all(8),
      thumbVisibility: WidgetStateProperty.all(false),
    );
  }

  static CardThemeData card(PharmaTokens tokens, {required bool isDark}) {
    return CardThemeData(
      color: tokens.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(
          color: tokens.border.withValues(alpha: isDark ? 0.6 : 0.85),
        ),
      ),
    );
  }

  static DialogThemeData dialog(PharmaTokens tokens, {required bool isDark}) {
    return DialogThemeData(
      backgroundColor: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(
          color: tokens.border.withValues(alpha: isDark ? 0.6 : 0.85),
        ),
      ),
    );
  }

  static BottomSheetThemeData bottomSheet(PharmaTokens tokens) {
    return BottomSheetThemeData(
      backgroundColor: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusMd)),
      ),
    );
  }

  static PopupMenuThemeData popupMenu(PharmaTokens tokens) {
    return PopupMenuThemeData(
      color: tokens.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusMd)),
      textStyle: TextStyle(color: tokens.textPrimary),
    );
  }

  static MenuThemeData menu(PharmaTokens tokens) {
    return MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(tokens.card),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusMd)),
        ),
      ),
    );
  }

  static CheckboxThemeData checkbox(ColorScheme scheme) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(scheme.onPrimary),
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  static SwitchThemeData switchTheme(ColorScheme scheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        return states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurface;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        return states.contains(WidgetState.selected)
            ? scheme.primary.withValues(alpha: 0.6)
            : scheme.onSurface.withValues(alpha: 0.25);
      }),
    );
  }

  static RadioThemeData radio(ColorScheme scheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        return states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurface;
      }),
    );
  }

  static SliderThemeData slider(ColorScheme scheme) {
    return SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.18),
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: scheme.inverseSurface,
      valueIndicatorTextStyle: TextStyle(color: scheme.onInverseSurface),
    );
  }

  static DividerThemeData divider(PharmaTokens tokens, {required bool isDark}) {
    return DividerThemeData(
      color: tokens.border.withValues(alpha: isDark ? 0.5 : 0.7),
    );
  }

  static DataTableThemeData dataTable(PharmaTokens tokens) {
    return DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(tokens.bgSecondary),
      headingTextStyle: TextStyle(
        color: tokens.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      dataTextStyle: TextStyle(color: tokens.textPrimary),
      dividerThickness: 1,
      horizontalMargin: tokens.density.md,
      columnSpacing: tokens.density.lg,
    );
  }

  static ListTileThemeData listTile(PharmaTokens tokens) {
    return ListTileThemeData(
      iconColor: tokens.textSecondary,
      textColor: tokens.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusMd)),
    );
  }

  static NavigationRailThemeData navigationRail(PharmaTokens tokens, ColorScheme scheme) {
    return NavigationRailThemeData(
      backgroundColor: tokens.bgSecondary,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: tokens.textSecondary),
      selectedLabelTextStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: tokens.textSecondary),
    );
  }

  static NavigationDrawerThemeData navigationDrawer(PharmaTokens tokens, ColorScheme scheme, {required bool isDark}) {
    return NavigationDrawerThemeData(
      backgroundColor: tokens.bgSecondary,
      indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
    );
  }

  static NavigationBarThemeData navigationBar(PharmaTokens tokens, ColorScheme scheme, {required bool isDark}) {
    return NavigationBarThemeData(
      backgroundColor: tokens.bgSecondary,
      indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  static ProgressIndicatorThemeData progressIndicator(ColorScheme scheme) {
    return ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.onSurface.withValues(alpha: 0.08),
      circularTrackColor: scheme.onSurface.withValues(alpha: 0.08),
    );
  }

  static TabBarThemeData tabBar(PharmaTokens tokens, ColorScheme scheme, {required bool isDark}) {
    return TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: tokens.textSecondary,
      indicatorColor: scheme.primary,
      dividerColor: tokens.border.withValues(alpha: isDark ? 0.5 : 0.7),
    );
  }
}
