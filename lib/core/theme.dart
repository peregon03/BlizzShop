import 'package:flutter/material.dart';

/// Tema oscuro con acento borgoña para BlizzShop
class AppTheme {
  AppTheme._();

  static const _burgundy = Color(0xFF8B1A2F);
  static const _burgundyLight = Color(0xFFB5263F);
  static const _burgundyDark = Color(0xFF5C0E1E);

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _burgundy,
      brightness: Brightness.dark,
      primary: _burgundyLight,
      onPrimary: Colors.white,
      secondary: _burgundy,
      tertiary: const Color(0xFFD4AF37), // dorado
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _burgundyLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _burgundyLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _burgundy;
            return const Color(0xFF2A2A2A);
          }),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: _burgundy,
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: _burgundy.withOpacity(0.3),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        modalBackgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E2E2E),
        thickness: 1,
      ),
    );
  }

  // Colores semánticos de stock
  static const stockOk = Color(0xFF4CAF50);       // verde
  static const stockMinimo = Color(0xFFFFC107);   // amber
  static const stockBajo = Color(0xFFFF9800);     // naranja
  static const stockAgotado = Color(0xFFF44336);  // rojo
}
