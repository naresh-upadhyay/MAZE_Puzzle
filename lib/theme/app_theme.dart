import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Base Cyber Neon Palette matching UI Screenshots
  static const Color bgDark = Color(0xFF060713);
  static const Color bgSurface = Color(0xFF0E122B);
  static const Color bgCard = Color(0xBF121838);
  static const Color borderGlow = Color(0x5900FF9D);

  static const Color primaryGlow = Color(0xFF00FF9D);
  static const Color secondaryGlow = Color(0xFF00FFFF);
  static const Color accentPink = Color(0xFFFF2A6D);
  static const Color accentPurple = Color(0xFF9D4EDD);
  static const Color accentGold = Color(0xFFFFC107);
  static const Color accentBlue = Color(0xFF00D2FF);

  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8E9BB5);

  // Theme color maps for Store Themes
  static Map<String, Color> themeColors = {
    'neon': const Color(0xFF00FF9D),
    'forest': const Color(0xFF00FF66),
    'ocean': const Color(0xFF00D2FF),
    'lava': const Color(0xFFFF3366),
    'space': const Color(0xFFB537FF),
  };

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryGlow,
      splashFactory: InkRipple.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: primaryGlow,
        secondary: secondaryGlow,
        surface: bgSurface,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 36, fontWeight: FontWeight.w900, color: textMain, letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 24, fontWeight: FontWeight.w800, color: primaryGlow, letterSpacing: 4,
        ),
        titleLarge: GoogleFonts.orbitron(
          fontSize: 18, fontWeight: FontWeight.w800, color: textMain,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.w500, color: textMain,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14, fontWeight: FontWeight.w400, color: textMuted,
        ),
      ),
    );
  }

  // Card Decoration with Glassmorphism Border Glow
  static BoxDecoration glassCardDecoration({Color? glowColor, double borderRadius = 16.0}) {
    final color = glowColor ?? primaryGlow;
    return BoxDecoration(
      color: bgCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: color.withValues(alpha: 0.35),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 15,
          spreadRadius: 1,
        ),
      ],
    );
  }

  // Primary Action Button Decoration
  static BoxDecoration primaryButtonDecoration({Color? color}) {
    final btnColor = color ?? primaryGlow;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [btnColor, btnColor.withValues(alpha: 0.85)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(50),
      boxShadow: [
        BoxShadow(
          color: btnColor.withValues(alpha: 0.5),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
