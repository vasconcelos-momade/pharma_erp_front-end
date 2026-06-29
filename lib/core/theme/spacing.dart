import 'package:flutter/widgets.dart';

import 'design_tokens.dart';

extension SpacingX on BuildContext {
  DensityTokens get spacing => pharmaTokens.density;
}

abstract final class Spacing {
  Spacing._();

  static const double zero = 0;
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s64 = 64;
  static const double s72 = 72;
  static const double s80 = 80;
  static const double s96 = 96;
  static const double s120 = 120;
  static const double s160 = 160;

  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value);
  static EdgeInsets symmetric({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: v);
  static EdgeInsets only({double l = 0, double t = 0, double r = 0, double b = 0}) =>
      EdgeInsets.only(left: l, top: t, right: r, bottom: b);
}

@Deprecated('Use context.spacing ou Spacing')
abstract final class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double gutter = 16;
  static const double page = 16;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(gutter, md, gutter, lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}
