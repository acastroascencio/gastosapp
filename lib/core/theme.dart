import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'storage_helper.dart';

// Proveedor global para manejar el tema (claro/oscuro) reactivamente y persistente
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() async {
    final modeStr = await StorageHelper.getThemeMode();
    if (modeStr == 'light') {
      GodfatherTheme.updateTheme(ThemeMode.light);
      state = ThemeMode.light;
    } else {
      GodfatherTheme.updateTheme(ThemeMode.dark);
      state = ThemeMode.dark;
    }
  }

  void toggleTheme() async {
    if (state == ThemeMode.dark) {
      GodfatherTheme.updateTheme(ThemeMode.light);
      state = ThemeMode.light;
      await StorageHelper.saveThemeMode('light');
    } else {
      GodfatherTheme.updateTheme(ThemeMode.dark);
      state = ThemeMode.dark;
      await StorageHelper.saveThemeMode('dark');
    }
  }
}

class GodfatherTheme {
  // Colores dinámicos mutables que cambian en runtime según el tema seleccionado
  static Color primaryGold = const Color(0xFFD4AF37); // Oro elegante
  static Color secondaryGold = const Color(0xFF996515); // Oro viejo / bronce
  static Color backgroundBlack = const Color(0xFF0B0B0B); // Negro carbón puro
  static Color surfaceDark = const Color(0xFF16161A); // Gris muy oscuro para tarjetas
  static Color surfaceDarkAlt = const Color(0xFF1D1D22); // Gris secundario para fondos
  static Color textLight = const Color(0xFFE5E5E7); // Blanco roto
  static Color textMuted = const Color(0xFF8E8E93); // Gris para texto secundario
  static Color alertRed = const Color(0xFFCF6679); // Rojo para alertas/gastos
  static Color successGreen = const Color(0xFF4CAF50); // Verde para abonos/ingresos
  static Color borderColor = const Color(0xFF2C2C30); // Bordes de tarjetas
  static Color iconColor = const Color(0xFFF2C94C); // Iconos de categorías

  // Actualiza los colores en caliente al cambiar de modo
  static void updateTheme(ThemeMode mode) {
    if (mode == ThemeMode.dark) {
      primaryGold = const Color(0xFFE0B93F);
      secondaryGold = const Color(0xFF996515);
      backgroundBlack = const Color(0xFF050505);
      surfaceDark = const Color(0xFF15151A);
      surfaceDarkAlt = const Color(0xFF1D1D22);
      textLight = const Color(0xFFF5F5F5);
      textMuted = const Color(0xFFC8C8C8);
      alertRed = const Color(0xFFE46F8C);
      successGreen = const Color(0xFF3FC15F);
      borderColor = const Color(0xFF2F2F35);
      iconColor = const Color(0xFFF2C94C);
    } else {
      primaryGold = const Color(0xFFA77C00);
      secondaryGold = const Color(0xFF996515);
      backgroundBlack = const Color(0xFFF7F7F4);
      surfaceDark = const Color(0xFFFFFFFF);
      surfaceDarkAlt = const Color(0xFFF0F0EC);
      textLight = const Color(0xFF171717);
      textMuted = const Color(0xFF4B4B4B);
      alertRed = const Color(0xFFC7365F);
      successGreen = const Color(0xFF1F8F43);
      borderColor = const Color(0xFFD8D8D2);
      iconColor = const Color(0xFF0F766E);
    }
  }

  // TEMA OSCURO PREMIUM
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: surfaceDark,
      colorScheme: ColorScheme.dark(
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
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGold, size: 28),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
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
          side: BorderSide(color: primaryGold, width: 1.5),
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
        labelStyle: TextStyle(color: textLight, fontSize: 16),
        hintStyle: TextStyle(color: textMuted, fontSize: 16),
        errorStyle: TextStyle(color: alertRed, fontSize: 15, fontWeight: FontWeight.bold),
        floatingLabelStyle: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: alertRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: alertRed, width: 1.5),
        ),
      ),
    );
  }

  // TEMA CLARO PREMIUM
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: surfaceDark,
      colorScheme: ColorScheme.light(
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
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGold, size: 28),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
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
          side: BorderSide(color: primaryGold, width: 1.5),
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
        fillColor: surfaceDarkAlt,
        labelStyle: TextStyle(color: textLight, fontSize: 16),
        hintStyle: TextStyle(color: textMuted, fontSize: 16),
        errorStyle: TextStyle(color: alertRed, fontSize: 15, fontWeight: FontWeight.bold),
        floatingLabelStyle: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: alertRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: alertRed, width: 1.5),
        ),
      ),
    );
  }
}
