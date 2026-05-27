import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../core/theme/app_theme.dart';
import 'providers/app_theme_mode_provider.dart';
import 'router/go_app_router.dart';

class PharmaErpApp extends ConsumerWidget {
  const PharmaErpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final mode = ref.watch(appThemeModeProvider);
    return MaterialApp.router(
      title: 'Pharma ERP',
      theme: AppTheme.lightEnterprise(),
      darkTheme: AppTheme.darkEnterprise(),
      themeMode: mode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 599, name: MOBILE),
            Breakpoint(start: 600, end: 1023, name: TABLET),
            Breakpoint(start: 1024, end: double.infinity, name: DESKTOP),
          ],
        );
      },
    );
  }
}
