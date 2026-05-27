import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Segmentação de ecrã para UX enterprise (mobile / tablet / desktop).
enum PharmaScreenSize {
  mobile,
  tablet,
  desktop,
}

/// Utilitários de layout e grelha para alta densidade operacional.
abstract final class PharmaScreenLayout {
  PharmaScreenLayout._();

  static PharmaScreenSize sizeOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= Breakpoints.desktop) return PharmaScreenSize.desktop;
    if (w >= Breakpoints.tablet) return PharmaScreenSize.tablet;
    return PharmaScreenSize.mobile;
  }

  static bool isMobile(BuildContext context) => sizeOf(context) == PharmaScreenSize.mobile;

  static bool isTablet(BuildContext context) => sizeOf(context) == PharmaScreenSize.tablet;

  static bool isDesktop(BuildContext context) => sizeOf(context) == PharmaScreenSize.desktop;

  /// PDV: catálogo + carrinho lado a lado a partir desta largura (prioridade tablet).
  static const double posSplitMinWidth = 720;

  static bool usePosSplitView(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= posSplitMinWidth;

  /// KPIs: 2 colunas em mobile (cartões pequenos), 2–4 em tablet/desktop.
  static int kpiCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= Breakpoints.desktop) return 4;
    if (width >= 840) return 3;
    if (width >= Breakpoints.tablet) return 2;
    return 2;
  }

  /// Largura/altura dos cartões KPI. Valores mais baixos = mais altura (evita overflow em grelha).
  static double kpiChildAspectRatio(PharmaScreenSize size) {
    return switch (size) {
      PharmaScreenSize.mobile => 2.05,
      PharmaScreenSize.tablet => 1.65,
      PharmaScreenSize.desktop => 1.38,
    };
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return switch (sizeOf(context)) {
      PharmaScreenSize.mobile => const EdgeInsets.fromLTRB(10, 10, 10, 12),
      PharmaScreenSize.tablet => const EdgeInsets.fromLTRB(16, 14, 16, 20),
      PharmaScreenSize.desktop => const EdgeInsets.fromLTRB(24, 20, 24, 32),
    };
  }
}

extension PharmaScreenSizeContext on BuildContext {
  PharmaScreenSize get pharmaScreen => PharmaScreenLayout.sizeOf(this);
}
