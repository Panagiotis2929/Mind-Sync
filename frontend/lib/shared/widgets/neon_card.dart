import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

/// NeonCard is the base surface component for all Mind-Sync panels.
/// It renders a dark card with a configurable neon border glow.
class NeonCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowOpacity;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool showGlow;

  const NeonCard({
    super.key,
    required this.child,
    this.glowColor   = MindSyncColors.neonCyan,
    this.glowOpacity = 0.0,
    this.padding,
    this.borderRadius,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(MindSyncDimensions.radiusMd);

    return Container(
      decoration: BoxDecoration(
        color:        MindSyncColors.backgroundCard,
        borderRadius: radius,
        border: Border.all(
          color: glowColor.withOpacity(showGlow ? 0.35 : 0.12),
          width: MindSyncDimensions.borderWidth,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color:       glowColor.withOpacity(glowOpacity.clamp(0.0, 0.25)),
                  blurRadius:  MindSyncDimensions.glowBlurRadius,
                  spreadRadius: MindSyncDimensions.glowSpread,
                  offset:      Offset.zero,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// GlowingText renders a label with a neon text-shadow effect.
class GlowingText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color glowColor;

  const GlowingText(
    this.text, {
    super.key,
    this.style,
    this.glowColor = MindSyncColors.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.headlineLarge!;
    return Text(
      text,
      style: base.copyWith(
        shadows: [
          Shadow(color: glowColor.withOpacity(0.8), blurRadius: 12),
          Shadow(color: glowColor.withOpacity(0.4), blurRadius: 24),
        ],
      ),
    );
  }
}

/// StatusBadge renders a small pill indicator with a dot and label.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool pulsing;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.pulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MindSyncDimensions.sm,
        vertical: MindSyncDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(MindSyncDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// NeonDivider renders a subtle horizontal rule with a neon gradient.
class NeonDivider extends StatelessWidget {
  final Color color;
  const NeonDivider({super.key, this.color = MindSyncColors.neonCyan});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color.withOpacity(0.4),
            color.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
