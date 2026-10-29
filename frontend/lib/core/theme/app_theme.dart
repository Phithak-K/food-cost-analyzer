import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand & Accent Colors (Modern Vercel / React Bits / Linear Style)
  static const Color primary = Color(0xFF10B981); // Emerald Green
  static const Color primaryNeon = Color(0xFF00F5A0); // High-contrast Neon
  static const Color primaryDark = Color(0xFF059669);
  static const Color secondary = Color(0xFF8B5CF6); // Neon Purple / Indigo
  static const Color accent = Color(0xFF00F5A0); // Neon Mint Accent
  
  // Matrix Quadrant Accents
  static const Color starGreen = Color(0xFF10B981); // Star - High Profit, High Volume
  static const Color plowhorseAmber = Color(0xFFF59E0B); // Plowhorse - Low Profit, High Volume
  static const Color puzzlePurple = Color(0xFF8B5CF6); // Puzzle - High Profit, Low Volume
  static const Color dogRose = Color(0xFFF43F5E); // Dog - Low Profit, Low Volume

  // Deep Dimensional Dark Palette (#0B0F19 / #0F172A)
  static const Color background = Color(0xFF0B0F19); // Deep dark canvas
  static const Color backgroundElevated = Color(0xFF0F172A); // Elevated canvas
  static const Color surface = Color(0xFF111827); // Dark card base
  static const Color surfaceGlass = Color(0x0FFFFFFF); // ~6% translucent white
  static const Color surfaceMuted = Color(0xFF1E293B); // Slate 800
  static const Color border = Color(0x14FFFFFF); // 8% translucent white for crisp borders
  static const Color borderSubtle = Color(0x0AFFFFFF); // 4% translucent white
  static const Color borderGlow = Color(0x3310B981); // Emerald glow border

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFF43F5E);
  static const Color info = Color(0xFF38BDF8);

  // Font Fallback Families for Web & Multi-Platform (Resolves CanvasKit Missing Font Warnings)
  static const List<String> fontFallbackFamilies = [
    'Prompt',
    'Noto Sans Thai',
    'Noto Sans',
    'Noto Color Emoji',
    'Segoe UI Emoji',
    'Apple Color Emoji',
    'sans-serif',
  ];

  // Modern Dark Dashboard Theme (Default)
  static ThemeData get darkTheme {
    final rawTheme = ThemeData.dark();
    final baseTextTheme = GoogleFonts.promptTextTheme(rawTheme.textTheme).apply(
      fontFamilyFallback: fontFallbackFamilies,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.prompt().fontFamily,
      fontFamilyFallback: fontFallbackFamilies,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: backgroundElevated,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        surfaceContainerLowest: background,
        surfaceContainerLow: backgroundElevated,
        surfaceContainer: surface,
        surfaceContainerHigh: surfaceMuted,
        outline: border,
        outlineVariant: borderSubtle,
        onPrimary: Color(0xFF0B0F19),
        onSurface: textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontSize: 18,
          letterSpacing: -0.2,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 15,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textPrimary,
          fontSize: 14,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontSize: 13,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: textMuted,
          fontSize: 12,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundElevated,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.prompt(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ).copyWith(fontFamilyFallback: fontFallbackFamilies),
        shape: const Border(bottom: BorderSide(color: border, width: 1)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.prompt(
          color: textMuted,
          fontSize: 13,
        ).copyWith(fontFamilyFallback: fontFallbackFamilies),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0B0F19),
          elevation: 0,
          shadowColor: primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.prompt(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ).copyWith(fontFamilyFallback: fontFallbackFamilies),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.prompt(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ).copyWith(fontFamilyFallback: fontFallbackFamilies),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: backgroundElevated,
        indicatorColor: Color(0x1F10B981),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return primary.withValues(alpha: 0.7);
          }
          if (states.contains(WidgetState.hovered)) {
            return primary.withValues(alpha: 0.5);
          }
          return Colors.white.withValues(alpha: 0.2);
        }),
        thickness: const WidgetStatePropertyAll(7.0),
        radius: const Radius.circular(8),
        thumbVisibility: const WidgetStatePropertyAll(true),
        interactive: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
    );
  }

  // Light Theme fallback if requested
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.promptTextTheme().apply(
      fontFamilyFallback: fontFallbackFamilies,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.prompt().fontFamily,
      fontFamilyFallback: fontFallbackFamilies,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      textTheme: baseTextTheme,
    );
  }
}
