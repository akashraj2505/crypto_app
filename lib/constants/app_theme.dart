import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CoinGecko's actual app uses a near-black background with flat surfaces
/// (no colored elevation tint), crisp white/gray text, and a single cool
/// accent color reserved for interactive elements — gain/loss green and red
/// are kept exclusive to price data so they always carry meaning.
class AppColors {
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF151A21);
  static const surfaceElevated = Color(0xFF1C232C);
  static const border = Color(0xFF2A323C);

  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFF8B93A1);
  static const textMuted = Color(0xFF5D6470);

  static const accent = Color(0xFF4F8EF7); // interactive elements only
  static const gain = Color(0xFF16C784);
  static const loss = Color(0xFFEA3943);
  static const watchlistStar = Color(0xFFF3BA2F);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        surfaceContainerHighest: AppColors.surfaceElevated,
        primary: AppColors.accent,
        secondary: AppColors.accent,
        error: AppColors.loss,
        onSurface: AppColors.textPrimary,
      ),
    );

    // Inter is the closest free match to the system sans CoinGecko uses —
    // tighter letter spacing and taller x-height than Material's default
    // Roboto, which is most of what was reading as "generic" before.
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        color: AppColors.textMuted,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      // Flat app bar: no elevation tint, no color bleed from the seed color.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.accent : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accent : AppColors.textMuted,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 24,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.accent.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}