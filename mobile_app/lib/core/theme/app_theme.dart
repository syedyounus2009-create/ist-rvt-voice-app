import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),

      // ── Typography ──────────────────────────────────────────────────────
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary, letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          headlineLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          bodyLarge: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w400,
            color: AppColors.textPrimary, height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w400,
            color: AppColors.textSecondary, height: 1.5,
          ),
          labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary, letterSpacing: 0.5,
          ),
        ),
      ),

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Input Fields ────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textHint,
        suffixIconColor: AppColors.textHint,
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Icon ────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceCard,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Switch ──────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textHint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.surfaceCard,
        ),
      ),
    );
  }
}
