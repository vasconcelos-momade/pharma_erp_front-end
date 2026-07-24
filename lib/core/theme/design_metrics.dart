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
  static const double controlHeight = 48;
  static const double compactControlHeight = 40;

  static const double iconMd = 24;
  static const double iconSm = 18;
  static const double avatarMd = 40;

  static const double buttonIconSize = iconSm;
  static const double buttonLoaderSize = iconSm;
  static const double buttonLoaderStrokeWidth = 2;
  static const double feedbackIconSize = iconMd;

  // Alturas de componentes (MD3 / prompt ERP)
  /// Altura visual partilhada por campos e botões de acção.
  static const double fieldHeightMin = minTouchTarget;
  static const double fieldHeightMax = 52;
  static const double buttonHeight = fieldHeightMin;
  static const double tabHeightMin = 44;
  static const double tabHeightMax = minTouchTarget;
  static const double toolbarHeight = fieldHeightMin;
  static const double tableRowHeightMin = 52;
  static const double tableRowHeightMax = 56;
  /// Botões circulares de paginação / segmentos.
  static const double paginationButtonSize = avatarMd;

  /// Controlo compacto (ex.: toggle da sidebar).
  static const double iconButtonCompactSize = iconMd + SpacingTokens.sm;

  /// Largura máxima do campo de pesquisa em toolbars (design system).
  static const double searchFieldMaxWidthDesktop = 320;
  static const double searchFieldMaxWidthTablet = 300;

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

  /// Presets de largura enterprise (Small / Medium / Large).
  static const double dialogSizeSmall = 400;
  static const double dialogSizeMedium = 560;
  static const double dialogSizeLarge = 720;

  static const double sideSheetSizeSmall = 400;
  static const double sideSheetSizeMedium = 560;
  static const double sideSheetSizeLarge = 640;

  /// Opacidade do scrim (modal barrier) do Design System.
  static const double overlayScrimOpacity = 0.38;

  /// Breakpoints de overlay (alinham com AdaptiveNavigator / side sheet).
  static const double overlayMobileBreakpoint = 768;
  static const double overlayDesktopBreakpoint = 1200;
}
