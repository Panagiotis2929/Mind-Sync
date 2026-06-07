import 'package:flutter/material.dart';

/// MindSyncColors defines the full cyberpunk/synth color system.
///
/// Design philosophy: Deep space blacks with neon electric accents.
/// Every color is purposefully named for semantic clarity.
abstract class MindSyncColors {
  // ── Background layers ──────────────────────────────────────────────────
  static const Color backgroundDeep    = Color(0xFF050810); // Near-void black
  static const Color backgroundSurface = Color(0xFF0A0F1E); // Dark navy canvas
  static const Color backgroundCard    = Color(0xFF0F172A); // Elevated card
  static const Color backgroundOverlay = Color(0xFF1A2540); // Modal/overlay

  // ── Neon primary palette ───────────────────────────────────────────────
  static const Color neonCyan          = Color(0xFF00F5FF); // Electric cyan – primary action
  static const Color neonPurple        = Color(0xFFBF00FF); // Vivid violet – secondary
  static const Color neonMagenta       = Color(0xFFFF00CC); // Hot magenta – accent
  static const Color neonGreen         = Color(0xFF00FF88); // Matrix green – success / active
  static const Color neonAmber         = Color(0xFFFFB800); // Warning / energy
  static const Color neonRed           = Color(0xFFFF2D55); // Error / danger

  // ── Muted / mid-tones ─────────────────────────────────────────────────
  static const Color glowCyan          = Color(0xFF0AF0FF); // Glow halo for cyan elements
  static const Color glowPurple        = Color(0xFF9B30FF); // Glow halo for purple elements
  static const Color mutedBlue         = Color(0xFF1E3A5F); // Inactive / disabled
  static const Color gridLine          = Color(0xFF1A2540); // Subtle grid lines

  // ── Text hierarchy ─────────────────────────────────────────────────────
  static const Color textPrimary       = Color(0xFFE2E8F0); // Main content text
  static const Color textSecondary     = Color(0xFF94A3B8); // Supporting text
  static const Color textMuted         = Color(0xFF475569); // Placeholder / disabled

  // ── Brainwave state colors ─────────────────────────────────────────────
  static const Color gammaColor        = Color(0xFFFF2D55); // Gamma – intense red
  static const Color betaColor         = Color(0xFFFF9F0A); // Beta  – warm amber
  static const Color alphaColor        = Color(0xFF00F5FF); // Alpha – cool cyan
  static const Color thetaColor        = Color(0xFFBF00FF); // Theta – deep violet
  static const Color deltaColor        = Color(0xFF007AFF); // Delta – calm blue

  // ── Session mode gradients ─────────────────────────────────────────────
  static const List<Color> focusGradient    = [Color(0xFF0AF0FF), Color(0xFF0055FF)];
  static const List<Color> sleepGradient    = [Color(0xFF1A0533), Color(0xFF0A1A4F)];
  static const List<Color> creativeGradient = [Color(0xFFBF00FF), Color(0xFFFF2D55)];
  static const List<Color> customGradient   = [Color(0xFF00FF88), Color(0xFF00B4D8)];

  // ── Waveform visualization ────────────────────────────────────────────
  static const Color waveformPrimary   = Color(0xFF00F5FF);
  static const Color waveformSecondary = Color(0xFFBF00FF);
  static const Color waveformGlow      = Color(0x4400F5FF); // 26% opacity glow

  // Returns the color associated with a brainwave target string.
  static Color forBrainwave(String state) {
    switch (state.toUpperCase()) {
      case 'GAMMA': return gammaColor;
      case 'BETA':  return betaColor;
      case 'ALPHA': return alphaColor;
      case 'THETA': return thetaColor;
      case 'DELTA': return deltaColor;
      default:      return neonCyan;
    }
  }

  // Returns the gradient for a session mode string.
  static List<Color> gradientForMode(String mode) {
    switch (mode.toUpperCase()) {
      case 'FOCUS':    return focusGradient;
      case 'SLEEP':    return sleepGradient;
      case 'CREATIVE': return creativeGradient;
      default:         return customGradient;
    }
  }
}
