import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tema global da app (Material light/dark).
class AppThemeMode extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeMode, ThemeMode>(AppThemeMode.new);
