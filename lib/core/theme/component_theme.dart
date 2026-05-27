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
}
