abstract class MindSyncDimensions {
  // ── Spacing scale (4px base unit) ─────────────────────────────────────
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;

  // ── Border radii ───────────────────────────────────────────────────────
  static const double radiusSm  = 6.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 20.0;
  static const double radiusXl  = 28.0;
  static const double radiusFull = 999.0;

  // ── Card / panel dimensions ────────────────────────────────────────────
  static const double cardElevation  = 0.0; // Flat design, glow via BoxShadow
  static const double borderWidth    = 1.0;
  static const double glowBlurRadius = 24.0;
  static const double glowSpread     = 0.0;

  // ── Waveform visualizer ───────────────────────────────────────────────
  static const double visualizerHeight    = 200.0;
  static const double waveformLineWidth   = 1.5;
  static const double waveformGlowWidth   = 4.0;

  // ── Slider ────────────────────────────────────────────────────────────
  static const double sliderTrackHeight   = 4.0;
  static const double sliderThumbRadius   = 10.0;

  // ── Icons ─────────────────────────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
}

abstract class MindSyncStrings {
  static const String appName     = 'Mind-Sync';
  static const String appTagline  = 'Neural Audio Architect';
  static const String apiBaseUrl  = 'http://localhost:8080';
  static const String apiVersion  = 'v1';
}
