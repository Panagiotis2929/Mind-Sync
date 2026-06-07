import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

/// BrainwaveIndicator renders a prominent display of the currently active
/// brainwave entrainment state with color-coded glow and descriptive metadata.
class BrainwaveIndicator extends StatelessWidget {
  final String brainwaveState; // "GAMMA" | "BETA" | "ALPHA" | "THETA" | "DELTA"
  final double beatFreqHz;
  final bool isActive;

  const BrainwaveIndicator({
    super.key,
    required this.brainwaveState,
    required this.beatFreqHz,
    this.isActive = false,
  });

  static const _metadata = {
    'GAMMA': (label: 'Gamma', range: '30–100 Hz', desc: 'Peak Cognitive Performance'),
    'BETA':  (label: 'Beta',  range: '13–30 Hz',  desc: 'Active Focus & Alertness'),
    'ALPHA': (label: 'Alpha', range: '8–13 Hz',   desc: 'Relaxed Awareness'),
    'THETA': (label: 'Theta', range: '4–8 Hz',    desc: 'Deep Meditation & Creativity'),
    'DELTA': (label: 'Delta', range: '0.5–4 Hz',  desc: 'Deep Restorative Sleep'),
  };

  @override
  Widget build(BuildContext context) {
    final color = MindSyncColors.forBrainwave(brainwaveState);
    final meta  = _metadata[brainwaveState] ??
        (label: brainwaveState, range: '—', desc: 'Custom State');

    return Container(
      padding: const EdgeInsets.all(MindSyncDimensions.md),
      decoration: BoxDecoration(
        color:        MindSyncColors.backgroundCard,
        borderRadius: BorderRadius.circular(MindSyncDimensions.radiusMd),
        border: Border.all(
          color: color.withOpacity(isActive ? 0.5 : 0.2),
          width: 1.0,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 20)]
            : null,
      ),
      child: Row(
        children: [
          // ── Animated frequency ring ─────────────────────────────
          _FrequencyRing(color: color, isActive: isActive),
          const SizedBox(width: MindSyncDimensions.md),

          // ── State metadata ──────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      meta.label.toUpperCase(),
                      style: TextStyle(
                        color:      color,
                        fontSize:   16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(width: MindSyncDimensions.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:        color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meta.range,
                        style: TextStyle(
                          color: color.withOpacity(0.8),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  meta.desc,
                  style: const TextStyle(
                    color:    MindSyncColors.textSecondary,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // ── Live beat frequency readout ─────────────────────────
          if (isActive)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  beatFreqHz.toStringAsFixed(2),
                  style: TextStyle(
                    color:      color,
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                const Text(
                  'Hz BEAT',
                  style: TextStyle(
                    color:    MindSyncColors.textMuted,
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// _FrequencyRing renders an animated circular ring that pulses when active.
class _FrequencyRing extends StatelessWidget {
  final Color color;
  final bool isActive;

  const _FrequencyRing({required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    Widget ring = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:  color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.6), width: 2),
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12)]
            : null,
      ),
      child: Center(
        child: Icon(Icons.waves_rounded, color: color, size: 22),
      ),
    );

    if (isActive) {
      ring = ring
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.06, duration: 1200.ms, curve: Curves.easeInOut);
    }

    return ring;
  }
}
