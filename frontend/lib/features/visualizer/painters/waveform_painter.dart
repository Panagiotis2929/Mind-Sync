import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../audio_engine/models/neural_blueprint.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';

/// WaveformPainter renders a real-time multi-layer waveform visualization
/// driven by the active NeuralBlueprint's mathematical parameters.
///
/// Rendering strategy:
///   - Layer 0 (primary): Animated composite sine wave at carrier + beat frequencies
///   - Layer 1 (secondary): Phase-offset harmonic at 50% opacity
///   - Glow pass: Wide, low-opacity stroke to simulate neon bloom
///   - Grid: Subtle horizontal and vertical reference lines
///   - Frequency labels: Rendered at wave peaks in the primary color
///
/// The animation is driven by an external [animationValue] (0.0–1.0 loop)
/// provided by an AnimationController in the parent widget.
class WaveformPainter extends CustomPainter {
  final NeuralBlueprint? blueprint;
  final double animationValue; // 0.0 → 1.0, cycles over time
  final Color primaryColor;
  final Color secondaryColor;
  final bool showGrid;
  final bool showLabels;

  WaveformPainter({
    required this.blueprint,
    required this.animationValue,
    this.primaryColor  = MindSyncColors.waveformPrimary,
    this.secondaryColor = MindSyncColors.waveformSecondary,
    this.showGrid    = true,
    this.showLabels  = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    if (blueprint == null || blueprint!.oscillators.isEmpty) {
      _drawIdleWave(canvas, size);
      return;
    }

    // Render each oscillator layer, back to front
    for (var i = blueprint!.oscillators.length - 1; i >= 0; i--) {
      final osc = blueprint!.oscillators[i];
      final isPrimary = i == 0;
      _drawOscillatorWave(canvas, size, osc, isPrimary, i);
    }

    // Noise floor visualization (subtle horizontal shimmer)
    if (blueprint!.noise.isActive) {
      _drawNoiseFloor(canvas, size);
    }

    if (showLabels && blueprint!.oscillators.isNotEmpty) {
      _drawFrequencyLabels(canvas, size);
    }
  }

  // ── Grid ──────────────────────────────────────────────────────────────

  void _drawGrid(Canvas canvas, Size size) {
    if (!showGrid) return;

    final gridPaint = Paint()
      ..color   = MindSyncColors.gridLine.withOpacity(0.4)
      ..strokeWidth = 0.5
      ..style   = PaintingStyle.stroke;

    const hLines = 4;
    const vLines = 8;

    for (var i = 1; i < hLines; i++) {
      final y = size.height * i / hLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 1; i < vLines; i++) {
      final x = size.width * i / vLines;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Center line (slightly brighter)
    final centerPaint = Paint()
      ..color       = MindSyncColors.gridLine.withOpacity(0.7)
      ..strokeWidth = 1.0
      ..style       = PaintingStyle.stroke;
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), centerPaint);
  }

  // ── Idle wave (no blueprint) ──────────────────────────────────────────

  void _drawIdleWave(Canvas canvas, Size size) {
    final path  = Path();
    final glowP = Path();
    final cy    = size.height / 2;
    final phase = animationValue * 2 * math.pi;
    const amplitude = 8.0;
    const frequency = 2.0;

    var first = true;
    for (var x = 0.0; x <= size.width; x += 1.5) {
      final t = x / size.width;
      final y = cy + amplitude * math.sin(frequency * 2 * math.pi * t + phase);
      if (first) { path.moveTo(x, y); glowP.moveTo(x, y); first = false; }
      else        { path.lineTo(x, y); glowP.lineTo(x, y); }
    }

    // Glow pass
    canvas.drawPath(glowP, Paint()
      ..color       = MindSyncColors.mutedBlue.withOpacity(0.3)
      ..strokeWidth = MindSyncDimensions.waveformGlowWidth
      ..style       = PaintingStyle.stroke
      ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 6));

    // Line pass
    canvas.drawPath(path, Paint()
      ..color       = MindSyncColors.mutedBlue.withOpacity(0.6)
      ..strokeWidth = MindSyncDimensions.waveformLineWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round);
  }

  // ── Oscillator wave ────────────────────────────────────────────────────

  void _drawOscillatorWave(
    Canvas canvas,
    Size size,
    OscillatorLayer osc,
    bool isPrimary,
    int layerIndex,
  ) {
    final path      = Path();
    final glowPath  = Path();
    final cy        = size.height / 2;

    // Map beat frequency to visible cycles: normalize so 1Hz = 1 cycle across width
    // We cap visible cycles to keep the waveform readable (not too dense)
    final beatHz   = osc.beatFreqHz.clamp(0.5, 40.0);
    final cycles   = beatHz.clamp(1.0, 16.0);
    final phase    = animationValue * 2 * math.pi;

    // Amplitude scales with oscillator amplitude and available height
    final maxAmp   = size.height * 0.42 * osc.amplitudeLinear;

    // Phase offset creates spatial separation between layers
    final layerPhaseShift = layerIndex * (math.pi / 3.0) + osc.phaseOffsetRad;

    final color    = isPrimary ? primaryColor : secondaryColor;
    final opacity  = isPrimary ? 1.0 : 0.55;

    var first = true;
    for (var x = 0.0; x <= size.width; x += 1.0) {
      final t   = x / size.width;
      // Composite wave: carrier envelope modulated by beat frequency
      final carrierPhase = 2 * math.pi * cycles * t + phase + layerPhaseShift;
      // Beat envelope creates the characteristic amplitude-modulation
      final beatEnvelope = 0.5 + 0.5 * math.cos(2 * math.pi * (beatHz / 40.0) * t * 2 + phase * 0.3);
      final y = cy + maxAmp * math.sin(carrierPhase) * beatEnvelope;

      if (first) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }

    // ── Glow pass (wide, blurred, low opacity) ────────────────────────
    canvas.drawPath(glowPath, Paint()
      ..color       = color.withOpacity(0.18 * opacity)
      ..strokeWidth = MindSyncDimensions.waveformGlowWidth * (isPrimary ? 1.0 : 0.6)
      ..style       = PaintingStyle.stroke
      ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 8));

    // ── Main line pass ────────────────────────────────────────────────
    canvas.drawPath(path, Paint()
      ..color       = color.withOpacity(0.9 * opacity)
      ..strokeWidth = MindSyncDimensions.waveformLineWidth * (isPrimary ? 1.0 : 0.7)
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round);

    // ── Filled area under the primary wave (subtle gradient fill) ────
    if (isPrimary) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, cy)
        ..lineTo(0, cy)
        ..close();

      final shader = LinearGradient(
        begin:  Alignment.topCenter,
        end:    Alignment.bottomCenter,
        colors: [color.withOpacity(0.12), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, Paint()
        ..shader = shader
        ..style  = PaintingStyle.fill);
    }
  }

  // ── Noise floor ────────────────────────────────────────────────────────

  void _drawNoiseFloor(Canvas canvas, Size size) {
    final rng       = math.Random(42); // Fixed seed for reproducible shimmer
    final cy        = size.height / 2;
    final amp       = size.height * 0.06 * blueprint!.noise.amplitudeLinear;
    final path      = Path();
    var first = true;

    // Animate noise phase by time offset
    final timeOffset = (animationValue * 1000).floor();

    for (var x = 0.0; x <= size.width; x += 4.0) {
      final noiseVal = (rng.nextDouble() * 2 - 1) * amp;
      // Mix with a slow sine for cohesion
      final y = cy + noiseVal + amp * 0.3 * math.sin(x * 0.05 + animationValue * math.pi + timeOffset);
      if (first) { path.moveTo(x, y); first = false; }
      else        { path.lineTo(x, y); }
    }

    canvas.drawPath(path, Paint()
      ..color       = MindSyncColors.neonGreen.withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style       = PaintingStyle.stroke);
  }

  // ── Frequency labels ───────────────────────────────────────────────────

  void _drawFrequencyLabels(Canvas canvas, Size size) {
    if (blueprint == null || blueprint!.oscillators.isEmpty) return;
    final osc = blueprint!.oscillators.first;

    final leftLabel  = '${osc.leftChannelHz.toStringAsFixed(1)} Hz';
    final rightLabel = '${osc.rightChannelHz.toStringAsFixed(1)} Hz';
    final beatLabel  = '△ ${osc.beatFreqHz.toStringAsFixed(2)} Hz';

    _drawLabel(canvas, leftLabel,  const Offset(8, 8),  MindSyncColors.neonCyan);
    _drawLabel(canvas, rightLabel, Offset(size.width - 80, 8), MindSyncColors.neonPurple);
    _drawLabel(canvas, beatLabel,  Offset(size.width / 2 - 40, 8), MindSyncColors.neonGreen);
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color:      color.withOpacity(0.85),
          fontSize:   10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.blueprint      != blueprint      ||
           oldDelegate.primaryColor   != primaryColor;
  }
}
