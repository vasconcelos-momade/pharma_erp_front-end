import 'package:flutter/widgets.dart';

import 'design_tokens.dart';

extension SpacingX on BuildContext {
  DensityTokens get spacing => pharmaTokens.density;
}

@Deprecated('Use context.spacing instead')
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
  static const double gutter = 24;
  static const double page = 32;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(lg, lg, lg, xxxl);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}
