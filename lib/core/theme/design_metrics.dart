export 'spacing.dart';
export 'spacing_tokens.dart';
export 'radius.dart';
export 'elevation.dart';
export 'shadows.dart';
export 'motion.dart';
export 'breakpoints.dart';
export 'width_tokens.dart';

import 'breakpoints.dart';
import 'spacing_tokens.dart';

/// Métricas estruturais do ERP (altura de componentes, sidebars, touch targets).
abstract final class DesignMetrics {
  DesignMetrics._();

  // Touch targets MD3
  static const double minTouchTarget = 48;

  static const double iconMd = 24;
  static const double iconSm = 18;
  static const double avatarMd = 40;

  static const double buttonIconSize = iconSm;
  static const double buttonLoaderSize = iconSm;
  static const double buttonLoaderStrokeWidth = 2;
  static const double feedbackIconSize = iconMd;

  // Alturas de componentes (MD3 / prompt ERP)
  static const double buttonHeight = minTouchTarget;
  static const double fieldHeightMin = minTouchTarget;
  static const double fieldHeightMax = 52;
  static const double tabHeightMin = 44;
  static const double tabHeightMax = minTouchTarget;
  static const double toolbarHeight = minTouchTarget;
  static const double tableRowHeightMin = 44;
  static const double tableRowHeightMax = minTouchTarget;

  // Shell / layout
  static const double topBarDesktop = 72;
  static const double topBarCompact = 56;
  static const double posHeader = 64;
  static const double posFooter = minTouchTarget;

  static const double sidebarExpanded = 280;
  static const double sidebarCollapsed = 88;
  static const double contentMaxWidth = 1400;

  static const double breakpointMobile = Breakpoints.mobile;
  static const double breakpointTablet = Breakpoints.tablet;
  static const double breakpointDesktop = Breakpoints.desktop;

  // Diálogos
  static const double dialogMobileHorizontalInset = SpacingTokens.lg;
  static const double dialogWidthFractionTablet = 0.88;
  static const double dialogWidthFractionDesktop = 0.5;
  static const double dialogWidthCapContentFraction = 0.45;
  static const double dialogMaxHeightFractionMobile = 0.92;
  static const double dialogMaxHeightFractionDesktop = 0.88;
  static const double dialogBodyMaxHeightFraction = 0.65;
  static const double dialogSelectableListHeightFraction = 0.32;
}
