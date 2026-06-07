import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

/// NeuralSlider is a branded slider component used for all synthesis parameter
/// controls. It shows a label, current formatted value, and a neon-styled track.
class NeuralSlider extends StatelessWidget {
  final String label;
  final String sublabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) formatValue;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final IconData? icon;

  const NeuralSlider({
    super.key,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
    this.min         = 0.0,
    this.max         = 1.0,
    this.divisions   = 100,
    this.formatValue = _defaultFormat,
    this.activeColor = MindSyncColors.neonCyan,
    this.icon,
  });

  static String _defaultFormat(double v) => '${(v * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row: icon, label, current value ─────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MindSyncDimensions.xs),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: MindSyncDimensions.iconSm, color: activeColor),
                const SizedBox(width: MindSyncDimensions.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color:      MindSyncColors.textPrimary,
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        color:    MindSyncColors.textMuted,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              // Current value badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(MindSyncDimensions.radiusSm),
                  border: Border.all(color: activeColor.withOpacity(0.3)),
                ),
                child: Text(
                  formatValue(value),
                  style: TextStyle(
                    color:      activeColor,
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ── Slider track ────────────────────────────────────────────
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:      activeColor,
            inactiveTrackColor:    MindSyncColors.mutedBlue.withOpacity(0.4),
            thumbColor:            activeColor,
            overlayColor:          activeColor.withOpacity(0.15),
            trackHeight:           MindSyncDimensions.sliderTrackHeight,
            thumbShape: _NeonThumbShape(color: activeColor),
          ),
          child: Slider(
            value:     value.clamp(min, max),
            min:       min,
            max:       max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// _NeonThumbShape renders the slider thumb as a glowing neon circle.
class _NeonThumbShape extends SliderComponentShape {
  final Color color;
  const _NeonThumbShape({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer glow
    canvas.drawCircle(
      center,
      MindSyncDimensions.sliderThumbRadius + 4,
      Paint()
        ..color      = color.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main thumb circle
    canvas.drawCircle(center, MindSyncDimensions.sliderThumbRadius, Paint()
      ..color = MindSyncColors.backgroundDeep);
    canvas.drawCircle(center, MindSyncDimensions.sliderThumbRadius, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);

    // Center dot
    canvas.drawCircle(center, 3, Paint()..color = color);
  }
}
