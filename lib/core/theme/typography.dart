import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// **Inter** corpo / UI; **Poppins** títulos (estilo executivo). SF Pro → Inter no ecossistema Flutter.
///
/// Na **web** usa apenas o `TextTheme` do Material (sem [GoogleFonts] em runtime), para evitar
/// downloads a `fonts.gstatic.com` no primeiro paint — o que costuma atrasar visivelmente o navegador.
abstract final class AppTypography {
  AppTypography._();

  static TextTheme textThemeFor(Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness).textTheme;
    if (kIsWeb) {
      return _webEnterpriseTextTheme(base);
    }
    final inter = GoogleFonts.interTextTheme(base);
    return GoogleFonts.poppinsTextTheme(inter).copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        height: 1.12,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2),
      headlineMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600, height: 1.22),
      headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25),
      titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 1.45),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        height: 1.2,
      ),
    );
  }

  static TextStyle _w(TextStyle? s) => s ?? const TextStyle();

  static TextTheme _webEnterpriseTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: _w(base.displayLarge).copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displayMedium: _w(base.displayMedium).copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        height: 1.12,
      ),
      displaySmall: _w(base.displaySmall).copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineLarge: _w(base.headlineLarge).copyWith(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2),
      headlineMedium: _w(base.headlineMedium).copyWith(fontSize: 28, fontWeight: FontWeight.w600, height: 1.22),
      headlineSmall: _w(base.headlineSmall).copyWith(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25),
      titleLarge: _w(base.titleLarge).copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27),
      titleMedium: _w(base.titleMedium).copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
      titleSmall: _w(base.titleSmall).copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
      bodyLarge: _w(base.bodyLarge).copyWith(fontSize: 16, fontWeight: FontWeight.w500, height: 1.45),
      bodyMedium: _w(base.bodyMedium).copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45),
      bodySmall: _w(base.bodySmall).copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
      labelLarge: _w(base.labelLarge).copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium: _w(base.labelMedium).copyWith(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelSmall: _w(base.labelSmall).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        height: 1.2,
      ),
    );
  }

  /// Legado — tema único; preferir [textThemeFor].
  static TextTheme get textTheme => textThemeFor(Brightness.dark);
}
