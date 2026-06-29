import 'package:flutter/widgets.dart';

abstract final class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double desktopLarge = 1536;
  static const double ultraWide = 1920;
  static const double foldable = 700;
  static const double watch = 300;
  static const double tv = 2560;

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < mobile;
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobile && MediaQuery.sizeOf(context).width < desktop;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;
  static bool isDesktopLarge(BuildContext context) => MediaQuery.sizeOf(context).width >= desktopLarge;

  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? desktopLarge,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.desktopLarge && desktopLarge != null) return desktopLarge;
    if (width >= Breakpoints.desktop && desktop != null) return desktop;
    if (width >= Breakpoints.tablet && tablet != null) return tablet;
    return mobile;
  }
}
