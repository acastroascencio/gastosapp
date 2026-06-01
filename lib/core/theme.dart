import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GodfatherTheme {
  // Colores principales
  static const Color primaryGold = Color(0xFFD4AF37); // Oro elegante
  static const Color secondaryGold = Color(0xFF996515); // Oro viejo / bronce
  static const Color backgroundBlack = Color(0xFF0B0B0B); // Negro carbón puro (#0B0B0B)
  static const Color surfaceDark = Color(0xFF16161A); // Gris muy oscuro para tarjetas
  static const Color textLight = Color(0xFFE5E5E7); // Blanco roto
  static const Color textMuted = Color(0xFF8E8E93); // Gris para texto secundario
  static const Color alertRed = Color(0xFFCF6679); // Rojo para alertas/gastos
  static const Color successGreen = Color(0xFF4CAF50); // Verde para abonos/ingresos

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: secondaryGold,
        surface: surfaceDark,
        error: alertRed,
        onPrimary: backgroundBlack,
        onSecondary: textLight,
        onSurface: textLight,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cinzel(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: primaryGold,
          letterSpacing: 1.5,
        ),
        displayMedium: GoogleFonts.cinzel(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: primaryGold,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          color: textLight,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          color: textLight,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: primaryGold,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGold, size: 28),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: backgroundBlack,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 18,
          ),
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGold,
          side: const BorderSide(color: primaryGold, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 18,
          ),
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGold,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          minimumSize: const Size(80, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundBlack,
        labelStyle: const TextStyle(color: textLight, fontSize: 16),
        hintStyle: const TextStyle(color: textMuted, fontSize: 16),
        errorStyle: const TextStyle(color: alertRed, fontSize: 15, fontWeight: FontWeight.bold),
        floatingLabelStyle: const TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: alertRed, width: 1.5),
        ),
      ),
    );
  }
}
