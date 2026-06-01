import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'storage_helper.dart';

class CategoryVisuals {
  final IconData icon;
  final Color color;
  final Color bgColor;

  const CategoryVisuals({
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

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
  static Color goldActive = const Color(0xFFF2C94C); // Dorado activo
  static Color secondaryGold = const Color(0xFF996515); // Oro viejo / bronce
  static Color backgroundBlack = const Color(0xFF050505); // Negro carbón puro
  static Color surfaceDark = const Color(0xFF141418); // Gris muy oscuro para tarjetas
  static Color surfaceDarkAlt = const Color(0xFF1D1D22); // Gris secundario para fondos
  static Color textLight = const Color(0xFFF5F5F5); // Blanco roto
  static Color textMuted = const Color(0xFFD0D0D0); // Gris para texto secundario
  static Color alertRed = const Color(0xFFFF4D6D); // Rojo para alertas/gastos
  static Color successGreen = const Color(0xFF22C55E); // Verde para abonos/ingresos
  static Color borderColor = const Color(0xFF33333A); // Bordes de tarjetas
  static Color iconColor = const Color(0xFFF2C94C); // Iconos de categorías
  static Color iconBgColor = const Color(0x29F2C94C); // Fondo circular de ícono (rgba(242, 201, 76, 0.16))
  static Color iconBorderColor = const Color(0x73F2C94C); // Borde circular de ícono (rgba(242, 201, 76, 0.45))

  // Actualiza los colores en caliente al cambiar de modo
  static void updateTheme(ThemeMode mode) {
    if (mode == ThemeMode.dark) {
      primaryGold = const Color(0xFFD4AF37);
      goldActive = const Color(0xFFF2C94C);
      secondaryGold = const Color(0xFF996515);
      backgroundBlack = const Color(0xFF050505);
      surfaceDark = const Color(0xFF141418);
      surfaceDarkAlt = const Color(0xFF1D1D22);
      textLight = const Color(0xFFF5F5F5);
      textMuted = const Color(0xFFD0D0D0);
      alertRed = const Color(0xFFFF4D6D);
      successGreen = const Color(0xFF22C55E);
      borderColor = const Color(0xFF33333A);
      iconColor = const Color(0xFFF2C94C);
      iconBgColor = const Color(0x29F2C94C);
      iconBorderColor = const Color(0x73F2C94C);
    } else {
      primaryGold = const Color(0xFF9A6F00);
      goldActive = const Color(0xFFB88700);
      secondaryGold = const Color(0xFF996515);
      backgroundBlack = const Color(0xFFF7F3EA);
      surfaceDark = const Color(0xFFFFFFFF);
      surfaceDarkAlt = const Color(0xFFF1EDE4);
      textLight = const Color(0xFF1F1F1F);
      textMuted = const Color(0xFF4A4A4A);
      alertRed = const Color(0xFFC1121F);
      successGreen = const Color(0xFF15803D);
      borderColor = const Color(0xFFD8D2C3);
      iconColor = const Color(0xFF0F766E);
      iconBgColor = const Color(0x240F766E);
      iconBorderColor = const Color(0x590F766E);
    }
  }

  static CategoryVisuals getCategoryVisuals(String categoryName) {
    final name = categoryName.trim().toLowerCase();
    
    switch (name) {
      case 'comida':
        return const CategoryVisuals(
          icon: RemixIcons.restaurant_fill,
          color: Color(0xFFF97316),
          bgColor: Color(0x26F97316), // 0.15 * 255 = 38 (0x26)
        );
      case 'transporte':
        return const CategoryVisuals(
          icon: RemixIcons.car_fill,
          color: Color(0xFF2563EB),
          bgColor: Color(0x262563EB),
        );
      case 'salud':
        return const CategoryVisuals(
          icon: RemixIcons.first_aid_kit_fill,
          color: Color(0xFFDC2626),
          bgColor: Color(0x26DC2626),
        );
      case 'ocio':
        return const CategoryVisuals(
          icon: RemixIcons.gamepad_fill,
          color: Color(0xFF9333EA),
          bgColor: Color(0x269333EA),
        );
      case 'educación':
      case 'educacion':
        return const CategoryVisuals(
          icon: RemixIcons.graduation_cap_fill,
          color: Color(0xFF0891B2),
          bgColor: Color(0x260891B2),
        );
      case 'ropa':
        return const CategoryVisuals(
          icon: RemixIcons.shirt_fill,
          color: Color(0xFFDB2777),
          bgColor: Color(0x26DB2777),
        );
      case 'mascotas':
        return const CategoryVisuals(
          icon: RemixIcons.bear_smile_fill,
          color: Color(0xFFCA8A04),
          bgColor: Color(0x26CA8A04),
        );
      case 'internet':
        return const CategoryVisuals(
          icon: RemixIcons.wifi_fill,
          color: Color(0xFF2563EB),
          bgColor: Color(0x262563EB),
        );
      case 'luz':
        return const CategoryVisuals(
          icon: RemixIcons.lightbulb_fill,
          color: Color(0xFFFACC15),
          bgColor: Color(0x2EFACC15), // 0.18 * 255 = 46 (0x2E)
        );
      case 'agua':
        return const CategoryVisuals(
          icon: RemixIcons.drop_fill,
          color: Color(0xFF0284C7),
          bgColor: Color(0x260284C7),
        );
      case 'gas':
        return const CategoryVisuals(
          icon: RemixIcons.fire_fill,
          color: Color(0xFFEA580C),
          bgColor: Color(0x26EA580C),
        );
      case 'seguridad':
        return const CategoryVisuals(
          icon: RemixIcons.shield_check_fill,
          color: Color(0xFF16A34A),
          bgColor: Color(0x2616A34A),
        );
      case 'alquiler':
      case 'alquiler / casa':
      case 'casa':
        return CategoryVisuals(
          icon: RemixIcons.home_4_fill,
          color: primaryGold,
          bgColor: primaryGold.withValues(alpha: 0.15),
        );
      case 'mantenimiento':
        return const CategoryVisuals(
          icon: RemixIcons.tools_fill,
          color: Color(0xFF64748B),
          bgColor: Color(0x2664748B),
        );
      case 'celular':
      case 'teléfono':
      case 'telefono':
        return const CategoryVisuals(
          icon: RemixIcons.smartphone_fill,
          color: Color(0xFF0F766E),
          bgColor: Color(0x260F766E),
        );
      case 'streaming':
        return const CategoryVisuals(
          icon: RemixIcons.tv_fill,
          color: Color(0xFF9333EA),
          bgColor: Color(0x269333EA),
        );
      case 'limpieza':
        return const CategoryVisuals(
          icon: RemixIcons.brush_fill,
          color: Color(0xFF0891B2),
          bgColor: Color(0x260891B2),
        );
      case 'compras casa':
      case 'compras del hogar':
      case 'compras':
      case 'crédito':
      case 'credito':
      case 'crédito / compras':
        return const CategoryVisuals(
          icon: RemixIcons.shopping_cart_fill,
          color: Color(0xFF7C3AED),
          bgColor: Color(0x267C3AED),
        );
      
      // Abonos categories
      case 'aporte mensual':
        return const CategoryVisuals(
          icon: RemixIcons.calendar_fill,
          color: Color(0xFF16A34A),
          bgColor: Color(0x2616A34A),
        );
      case 'reembolso':
        return const CategoryVisuals(
          icon: RemixIcons.refund_fill,
          color: Color(0xFF0F766E),
          bgColor: Color(0x260F766E),
        );
      case 'fondo común':
      case 'fondo comun':
        return const CategoryVisuals(
          icon: RemixIcons.team_fill,
          color: Color(0xFF2563EB),
          bgColor: Color(0x262563EB),
        );
      case 'pago comp.':
      case 'pago compartido':
        return const CategoryVisuals(
          icon: RemixIcons.share_fill,
          color: Color(0xFFF97316),
          bgColor: Color(0x26F97316),
        );
      case 'sueldo':
        return const CategoryVisuals(
          icon: RemixIcons.briefcase_fill,
          color: Color(0xFFCA8A04),
          bgColor: Color(0x26CA8A04),
        );
      case 'extra':
        return const CategoryVisuals(
          icon: RemixIcons.add_circle_fill,
          color: Color(0xFF22C55E),
          bgColor: Color(0x2622C55E),
        );
      case 'venta':
        return const CategoryVisuals(
          icon: RemixIcons.store_fill,
          color: Color(0xFFDB2777),
          bgColor: Color(0x26DB2777),
        );
      default:
        return const CategoryVisuals(
          icon: RemixIcons.more_fill,
          color: Color(0xFF64748B),
          bgColor: Color(0x2E64748B), // 0.18 * 255 = 46 (0x2E)
        );
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
