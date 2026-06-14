/// Métricas do design system (única fonte de valores numéricos de layout).
abstract final class DesignMetrics {
  DesignMetrics._();

  /// Alvo táctil mínimo — botões, icon buttons, inputs (Material 3).
  static const double minTouchTarget = 48;

  static const double iconMd = 24;
  static const double iconSm = 18;
  static const double avatarMd = 40;

  /// Ícone dentro de botões compactos (IconButton, FilledButton.icon, etc.).
  static const double buttonIconSize = iconSm;

  /// Spinner inline em botões (FilledButton, OutlinedButton, etc.).
  static const double buttonLoaderSize = iconSm;
  static const double buttonLoaderStrokeWidth = 2;

  /// Ícone em SnackBars e banners de feedback leve.
  static const double feedbackIconSize = iconMd;

  static const double topBarDesktop = 72;
  static const double topBarCompact = 56;
  static const double posHeader = 64;
  static const double posFooter = 48;

  static const double sidebarExpanded = 280;
  static const double sidebarCollapsed = 88;
  static const double contentMaxWidth = 1400;

  /// Breakpoints de layout (dialogs, PDV, shell).
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 1024;

  /// Margem horizontal de dialogs em viewports mobile (gutter padrão).
  static const double dialogMobileHorizontalInset = 16;

  /// Fração da largura útil em tablet/desktop (sem px fixos de largura de modal).
  static const double dialogWidthFractionTablet = 0.88;
  static const double dialogWidthFractionDesktop = 0.5;
  static const double dialogWidthCapContentFraction = 0.45;

  /// Frações verticais de dialogs para manter layouts responsivos sem alturas fixas.
  static const double dialogMaxHeightFractionMobile = 0.92;
  static const double dialogMaxHeightFractionDesktop = 0.88;
  static const double dialogBodyMaxHeightFraction = 0.65;
  static const double dialogSelectableListHeightFraction = 0.32;
}
