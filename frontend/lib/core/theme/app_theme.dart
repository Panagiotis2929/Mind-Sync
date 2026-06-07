import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';

/// MindSyncTheme builds the full MaterialApp ThemeData for the cyberpunk aesthetic.
abstract class MindSyncTheme {
  static ThemeData get dark {
    const fontFamily = 'monospace'; // Clean mono for that terminal-engineer feel

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MindSyncColors.backgroundDeep,
      colorScheme: const ColorScheme.dark(
        primary:    MindSyncColors.neonCyan,
        secondary:  MindSyncColors.neonPurple,
        tertiary:   MindSyncColors.neonGreen,
        error:      MindSyncColors.neonRed,
        surface:    MindSyncColors.backgroundCard,
        onPrimary:  MindSyncColors.backgroundDeep,
        onSecondary: MindSyncColors.backgroundDeep,
        onSurface:  MindSyncColors.textPrimary,
      ),

      // ── Typography ─────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: MindSyncColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: MindSyncColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: MindSyncColors.neonCyan,
          letterSpacing: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: MindSyncColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          color: MindSyncColors.textPrimary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: MindSyncColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: MindSyncColors.textMuted,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: MindSyncColors.neonCyan,
          letterSpacing: 1.5,
        ),
      ),

      // ── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: MindSyncColors.backgroundDeep,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MindSyncColors.neonCyan,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: MindSyncColors.neonCyan),
      ),

      // ── Card ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: MindSyncColors.backgroundCard,
        elevation: MindSyncDimensions.cardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MindSyncDimensions.radiusMd),
          side: const BorderSide(
            color: MindSyncColors.gridLine,
            width: MindSyncDimensions.borderWidth,
          ),
        ),
      ),

      // ── Elevated button ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MindSyncColors.neonCyan,
          foregroundColor: MindSyncColors.backgroundDeep,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MindSyncDimensions.radiusSm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Slider ─────────────────────────────────────────────────────────
      sliderTheme: const SliderThemeData(
        activeTrackColor: MindSyncColors.neonCyan,
        inactiveTrackColor: MindSyncColors.mutedBlue,
        thumbColor: MindSyncColors.neonCyan,
        overlayColor: Color(0x2200F5FF),
        valueIndicatorColor: MindSyncColors.backgroundOverlay,
        trackHeight: MindSyncDimensions.sliderTrackHeight,
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: MindSyncColors.gridLine,
        thickness: 1,
        space: 0,
      ),

      // ── Icon ───────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: MindSyncColors.neonCyan,
        size: MindSyncDimensions.iconMd,
      ),
    );
  }
}
