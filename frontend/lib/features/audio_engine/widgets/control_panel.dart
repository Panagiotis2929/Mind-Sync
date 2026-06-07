import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../audio_engine/bloc/audio_engine_bloc.dart';
import '../../audio_engine/models/synthesis_parameters.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../shared/widgets/neural_slider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';

/// ControlPanel is the primary user interaction surface.
/// It renders session mode chips, all parameter sliders, oscillator mode
/// selectors, and the main play/stop transport control.
class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioEngineBloc, AudioEngineState>(
      builder: (context, state) {
        final params  = state.parameters;
        final playing = state.isPlaying;
        final computing = state.isComputing;

        return NeonCard(
          padding: const EdgeInsets.all(MindSyncDimensions.md),
          glowColor: playing ? MindSyncColors.neonCyan : MindSyncColors.mutedBlue,
          showGlow: playing,
          glowOpacity: 0.08,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Session mode selector ──────────────────────────────
              _SectionHeader(label: 'SESSION MODE', icon: Icons.tune_rounded),
              const SizedBox(height: MindSyncDimensions.sm),
              _SessionModeSelector(current: params.sessionMode, playing: playing),

              const SizedBox(height: MindSyncDimensions.lg),
              const NeonDivider(),
              const SizedBox(height: MindSyncDimensions.lg),

              // ── Neural tuning sliders ──────────────────────────────
              _SectionHeader(label: 'NEURAL TUNING', icon: Icons.psychology_rounded),
              const SizedBox(height: MindSyncDimensions.md),

              NeuralSlider(
                label:       'Focus Depth',
                sublabel:    'Cognitive engagement intensity',
                value:       params.focusDepth,
                activeColor: MindSyncColors.neonCyan,
                icon:        Icons.center_focus_strong_rounded,
                onChanged: (v) => _emit(context, params.copyWith(focusDepth: v)),
              ),

              const SizedBox(height: MindSyncDimensions.md),

              NeuralSlider(
                label:       'Calm Level',
                sublabel:    'Parasympathetic nervous system activation',
                value:       params.calmLevel,
                activeColor: MindSyncColors.thetaColor,
                icon:        Icons.spa_rounded,
                onChanged: (v) => _emit(context, params.copyWith(calmLevel: v)),
              ),

              const SizedBox(height: MindSyncDimensions.md),

              NeuralSlider(
                label:       'Energy Level',
                sublabel:    'Arousal and alertness drive',
                value:       params.energyLevel,
                activeColor: MindSyncColors.neonAmber,
                icon:        Icons.bolt_rounded,
                onChanged: (v) => _emit(context, params.copyWith(energyLevel: v)),
              ),

              const SizedBox(height: MindSyncDimensions.lg),
              const NeonDivider(),
              const SizedBox(height: MindSyncDimensions.lg),

              // ── Oscillator mode ────────────────────────────────────
              _SectionHeader(label: 'OSCILLATOR MODE', icon: Icons.graphic_eq_rounded),
              const SizedBox(height: MindSyncDimensions.sm),
              _OscillatorModeSelector(current: params.oscillatorMode, playing: playing),

              const SizedBox(height: MindSyncDimensions.lg),
              const NeonDivider(),
              const SizedBox(height: MindSyncDimensions.lg),

              // ── Noise layer ────────────────────────────────────────
              _SectionHeader(label: 'NOISE LAYER', icon: Icons.blur_on_rounded),
              const SizedBox(height: MindSyncDimensions.sm),
              _NoiseProfileSelector(current: params.noiseProfile, playing: playing),
              const SizedBox(height: MindSyncDimensions.md),
              NeuralSlider(
                label:       'Noise Volume',
                sublabel:    'Spectral masking intensity',
                value:       params.noiseVolume,
                activeColor: MindSyncColors.neonGreen,
                icon:        Icons.volume_up_rounded,
                onChanged: (v) => _emit(context, params.copyWith(noiseVolume: v)),
              ),

              const SizedBox(height: MindSyncDimensions.lg),
              const NeonDivider(),
              const SizedBox(height: MindSyncDimensions.lg),

              // ── Master volume ──────────────────────────────────────
              NeuralSlider(
                label:       'Master Volume',
                sublabel:    'Output gain (dBFS)',
                value:       params.masterVolume,
                activeColor: MindSyncColors.neonMagenta,
                icon:        Icons.speaker_rounded,
                formatValue: (v) => '${(v * 100).round()}%',
                onChanged: (v) => _emit(context, params.copyWith(masterVolume: v)),
              ),

              const SizedBox(height: MindSyncDimensions.xl),

              // ── Transport: Play / Stop ─────────────────────────────
              _TransportButton(playing: playing, computing: computing),
            ],
          ),
        );
      },
    );
  }

  void _emit(BuildContext context, SynthesisParameters params) {
    context.read<AudioEngineBloc>().add(AudioEngineParametersChanged(params));
  }
}

// ── Session mode chip row ──────────────────────────────────────────────────

class _SessionModeSelector extends StatelessWidget {
  final SessionMode current;
  final bool playing;

  const _SessionModeSelector({required this.current, required this.playing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SessionMode.values.map((mode) {
        final isSelected = mode == current;
        final colors = MindSyncColors.gradientForMode(mode.apiValue);
        final color  = colors.first;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                final bloc = context.read<AudioEngineBloc>();
                final current = bloc.state.parameters;
                bloc.add(AudioEngineParametersChanged(
                  current.copyWith(sessionMode: mode),
                ));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:        isSelected ? color.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(MindSyncDimensions.radiusSm),
                  border: Border.all(
                    color: isSelected ? color.withOpacity(0.7) : MindSyncColors.gridLine,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _modeIcon(mode),
                      size:  16,
                      color: isSelected ? color : MindSyncColors.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.label.toUpperCase(),
                      style: TextStyle(
                        color:      isSelected ? color : MindSyncColors.textMuted,
                        fontSize:   9,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _modeIcon(SessionMode mode) {
    switch (mode) {
      case SessionMode.focus:    return Icons.center_focus_strong_rounded;
      case SessionMode.sleep:    return Icons.bedtime_rounded;
      case SessionMode.creative: return Icons.auto_awesome_rounded;
      case SessionMode.custom:   return Icons.tune_rounded;
    }
  }
}

// ── Oscillator mode selector ───────────────────────────────────────────────

class _OscillatorModeSelector extends StatelessWidget {
  final OscillatorModeType current;
  final bool playing;

  const _OscillatorModeSelector({required this.current, required this.playing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: OscillatorModeType.values.map((mode) {
        final isSelected = mode == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                final bloc = context.read<AudioEngineBloc>();
                bloc.add(AudioEngineParametersChanged(
                  bloc.state.parameters.copyWith(oscillatorMode: mode),
                ));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MindSyncColors.neonPurple.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(MindSyncDimensions.radiusSm),
                  border: Border.all(
                    color: isSelected
                        ? MindSyncColors.neonPurple.withOpacity(0.5)
                        : MindSyncColors.gridLine,
                  ),
                ),
                child: Text(
                  mode.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? MindSyncColors.neonPurple
                        : MindSyncColors.textMuted,
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Noise profile selector ─────────────────────────────────────────────────

class _NoiseProfileSelector extends StatelessWidget {
  final NoiseProfileMode current;
  final bool playing;

  const _NoiseProfileSelector({required this.current, required this.playing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: NoiseProfileMode.values.map((profile) {
        final isSelected = profile == current;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () {
                final bloc = context.read<AudioEngineBloc>();
                bloc.add(AudioEngineParametersChanged(
                  bloc.state.parameters.copyWith(noiseProfile: profile),
                ));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MindSyncColors.neonGreen.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(MindSyncDimensions.radiusSm),
                  border: Border.all(
                    color: isSelected
                        ? MindSyncColors.neonGreen.withOpacity(0.5)
                        : MindSyncColors.gridLine,
                  ),
                ),
                child: Text(
                  profile.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? MindSyncColors.neonGreen
                        : MindSyncColors.textMuted,
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Transport button ───────────────────────────────────────────────────────

class _TransportButton extends StatelessWidget {
  final bool playing;
  final bool computing;

  const _TransportButton({required this.playing, required this.computing});

  @override
  Widget build(BuildContext context) {
    final label = computing
        ? 'COMPUTING...'
        : playing
            ? 'STOP SESSION'
            : 'BEGIN SESSION';

    final color = playing ? MindSyncColors.neonRed : MindSyncColors.neonCyan;
    final icon  = computing
        ? Icons.sync_rounded
        : playing
            ? Icons.stop_rounded
            : Icons.play_arrow_rounded;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GestureDetector(
        onTap: computing
            ? null
            : () {
                final bloc = context.read<AudioEngineBloc>();
                if (playing) {
                  bloc.add(const AudioEngineStopRequested());
                } else {
                  bloc.add(const AudioEngineStartRequested());
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: color.withOpacity(computing ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(MindSyncDimensions.radiusSm),
            border: Border.all(color: color.withOpacity(computing ? 0.3 : 0.7)),
            boxShadow: (!computing && playing)
                ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (computing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MindSyncColors.neonCyan,
                  ),
                )
              else
                Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color:      computing ? MindSyncColors.textMuted : color,
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: MindSyncDimensions.iconSm, color: MindSyncColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color:      MindSyncColors.textMuted,
            fontSize:   10,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}
