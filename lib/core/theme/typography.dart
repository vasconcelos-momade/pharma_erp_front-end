import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// **Inter** corpo / UI; **Poppins** títulos (estilo executivo).
///
/// Na **web** usa apenas o `TextTheme` do Material (sem [GoogleFonts] em runtime).
///
/// Escala oficial do Design System:
/// - Display: 28 / 600
/// - Titulo de pagina: 20 / 600
/// - Titulo de secao e card: 16 / 600
/// - AppBar: 18 / 600
/// - Tabs: 14 / 500
/// - Label: 13 / 500
/// - Texto principal: 14 / 400
/// - Texto secundario: 13 / 400
/// - Caption / metadata: 12 / 400
abstract final class AppTypography {
  AppTypography._();

  /// Monospace para códigos, números tabulares e IDs.
  static TextStyle monospace({
    required Brightness brightness,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final theme = textThemeFor(brightness);
    final base = theme.bodySmall ?? const TextStyle();
    final fallback = base.copyWith(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: fontSize ?? base.fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      height: 1.35,
    );
    if (kIsWeb) return fallback;
    return GoogleFonts.jetBrainsMono(textStyle: fallback);
  }

  /// Caption — alias de [TextTheme.bodySmall].
  static TextStyle caption(TextTheme theme) => theme.erpCaption;

  /// Overline — alias de [TextTheme.labelSmall] com tracking ERP.
  static TextStyle overline(TextTheme theme) => theme.erpOverline;

  /// AppBar discreta (18px) — apenas contexto da rota, não o registo.
  static TextStyle appBarTitle(TextTheme theme) => theme.erpAppBarTitle;

  /// Título de página no conteúdo — escala oficial do ERP.
  static TextStyle pageTitle(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return theme.erpPageTitle;
  }

  /// KPI: rótulo superior compacto.
  static TextStyle kpiLabel(TextTheme theme, {bool compact = true}) {
    return compact ? theme.erpOverline : theme.labelSmall ?? theme.erpCaption;
  }

  /// KPI: valor numérico.
  static TextStyle kpiValue(TextTheme theme, {bool compact = true}) {
    return compact
        ? (theme.titleLarge ?? theme.erpCardTitle)
        : (theme.erpDisplayLarge);
  }

  static TextTheme textThemeFor(Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness).textTheme;
    if (kIsWeb) {
      return _webEnterpriseTextTheme(base);
    }
    final inter = GoogleFonts.interTextTheme(base);
    return GoogleFonts.poppinsTextTheme(inter).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.15,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.15,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.3,
      ),
    );
  }

  static TextStyle _w(TextStyle? s) => s ?? const TextStyle();

  static TextTheme _webEnterpriseTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: _w(base.displayLarge).copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.15,
      ),
      displayMedium: _w(base.displayMedium).copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.15,
      ),
      displaySmall: _w(base.displaySmall).copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.15,
      ),
      headlineLarge: _w(base.headlineLarge).copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineMedium: _w(base.headlineMedium).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineSmall: _w(base.headlineSmall).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleLarge: _w(base.titleLarge).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleMedium: _w(base.titleMedium).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleSmall: _w(base.titleSmall).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      bodyLarge: _w(base.bodyLarge).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodyMedium: _w(base.bodyMedium).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      bodySmall: _w(base.bodySmall).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: _w(base.labelLarge).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelMedium: _w(base.labelMedium).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelSmall: _w(base.labelSmall).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.3,
      ),
    );
  }

  /// Legado — preferir [textThemeFor].
  static TextTheme get textTheme => textThemeFor(Brightness.dark);
}

/// Papéis tipográficos ERP sobre [TextTheme] Material 3.
extension EnterpriseTextTheme on TextTheme {
  TextStyle get erpDisplayLarge => displayLarge ?? const TextStyle();
  TextStyle get erpDisplayMedium => displayMedium ?? const TextStyle();
  TextStyle get erpPageTitle => headlineLarge ?? const TextStyle();
  TextStyle get erpSectionTitle => headlineMedium ?? const TextStyle();
  TextStyle get erpCardTitle => titleLarge ?? const TextStyle();
  TextStyle get erpAppBarTitle => (titleLarge ?? const TextStyle()).copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      );

  /// AppBar mantém a escala oficial em todos os breakpoints.
  TextStyle erpAppBarTitleFor(BuildContext context) {
    return erpAppBarTitle;
  }
  TextStyle get erpTabLabel => titleSmall ?? const TextStyle();
  TextStyle get erpLabel => labelLarge ?? const TextStyle();
  TextStyle get erpBody => bodyLarge ?? const TextStyle();
  TextStyle get erpBodySecondary => bodyMedium ?? const TextStyle();
  TextStyle get erpCaption => bodySmall ?? const TextStyle();
  TextStyle get erpOverline => (labelSmall ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.2,
      );
}
