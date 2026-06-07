import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/audio_engine/bloc/audio_engine_bloc.dart';
import '../../features/audio_engine/widgets/control_panel.dart';
import '../../features/presets/widgets/presets_panel.dart';
import '../../features/session_history/widgets/session_history_panel.dart';
import '../../features/visualizer/widgets/waveform_visualizer.dart';
import '../../shared/widgets/brainwave_indicator.dart';
import '../../shared/widgets/neon_card.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

/// HomeScreen is the root view of Mind-Sync. It composes all major panels
/// into a scrollable, responsive layout:
///
///   ┌─────────────────────────────────┐
///   │  AppBar: logo + backend status  │
///   ├─────────────────────────────────┤
///   │  Waveform Visualizer            │
///   ├─────────────────────────────────┤
///   │  Brainwave Indicator            │
///   ├─────────────────────────────────┤
///   │  Control Panel (sliders+play)   │
///   ├─────────────────────────────────┤
///   │  Presets Panel (tabs)           │
///   ├─────────────────────────────────┤
///   │  Session History Panel          │
///   └─────────────────────────────────┘
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MindSyncColors.backgroundDeep,
      body: SafeArea(
        child: Column(
          children: [
            _AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: MindSyncDimensions.md,
                  vertical: MindSyncDimensions.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Waveform visualizer ──────────────────────
                    BlocBuilder<AudioEngineBloc, AudioEngineState>(
                      builder: (context, state) => WaveformVisualizer(
                        blueprint: state.activeBlueprint,
                        isPlaying: state.isPlaying,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0),

                    const SizedBox(height: MindSyncDimensions.md),

                    // ── Session timer (only during playback) ─────
                    BlocBuilder<AudioEngineBloc, AudioEngineState>(
                      buildWhen: (p, c) =>
                          p.isPlaying != c.isPlaying ||
                          p.sessionElapsedSec != c.sessionElapsedSec,
                      builder: (context, state) {
                        if (!state.isPlaying) return const SizedBox.shrink();
                        return _SessionTimer(elapsedSec: state.sessionElapsedSec)
                            .animate()
                            .fadeIn(duration: 400.ms);
                      },
                    ),

                    // ── Brainwave indicator ──────────────────────
                    BlocBuilder<AudioEngineBloc, AudioEngineState>(
                      builder: (context, state) {
                        final blueprint = state.activeBlueprint;
                        final brainwave = blueprint?.brainwaveTarget ?? 'ALPHA';
                        final beatHz    = blueprint?.primaryBeatHz    ?? 10.0;
                        return BrainwaveIndicator(
                          brainwaveState: brainwave,
                          beatFreqHz:     beatHz,
                          isActive:       state.isPlaying,
                        );
                      },
                    ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                    const SizedBox(height: MindSyncDimensions.md),

                    // ── Error banner ─────────────────────────────
                    BlocBuilder<AudioEngineBloc, AudioEngineState>(
                      buildWhen: (p, c) => p.hasError != c.hasError,
                      builder: (context, state) {
                        if (!state.hasError) return const SizedBox.shrink();
                        return _ErrorBanner(message: state.errorMessage ?? 'Unknown error');
                      },
                    ),

                    const SizedBox(height: MindSyncDimensions.md),

                    // ── Control panel ────────────────────────────
                    const ControlPanel()
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 500.ms)
                        .slideY(begin: 0.05, end: 0),

                    const SizedBox(height: MindSyncDimensions.md),

                    // ── Presets panel ────────────────────────────
                    const PresetsPanel()
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms),

                    const SizedBox(height: MindSyncDimensions.md),

                    // ── Session history ──────────────────────────
                    const SessionHistoryPanel()
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 500.ms),

                    const SizedBox(height: MindSyncDimensions.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App header ─────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MindSyncDimensions.md,
        vertical: MindSyncDimensions.sm + 2,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MindSyncColors.gridLine),
        ),
      ),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: MindSyncColors.focusGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: MindSyncColors.neonCyan.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.waves_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: MindSyncDimensions.sm),

          // Wordmark
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MIND-SYNC',
                style: TextStyle(
                  color:      MindSyncColors.neonCyan,
                  fontSize:   14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 3.0,
                ),
              ),
              Text(
                'NEURAL AUDIO ARCHITECT',
                style: TextStyle(
                  color:    MindSyncColors.textMuted,
                  fontSize: 8,
                  fontFamily: 'monospace',
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Backend status indicator
          BlocBuilder<AudioEngineBloc, AudioEngineState>(
            buildWhen: (p, c) => p.isBackendReachable != c.isBackendReachable,
            builder: (context, state) {
              return StatusBadge(
                label: state.isBackendReachable ? 'DSP ONLINE' : 'OFFLINE',
                color: state.isBackendReachable
                    ? MindSyncColors.neonGreen
                    : MindSyncColors.neonRed,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Session timer ──────────────────────────────────────────────────────────

class _SessionTimer extends StatelessWidget {
  final double elapsedSec;
  const _SessionTimer({required this.elapsedSec});

  @override
  Widget build(BuildContext context) {
    final mins = (elapsedSec / 60).floor();
    final secs = (elapsedSec % 60).floor();
    final display = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: MindSyncDimensions.md),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: MindSyncColors.neonRed,
                boxShadow: [
                  BoxShadow(color: MindSyncColors.neonRed, blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SESSION $display',
              style: const TextStyle(
                color:      MindSyncColors.neonRed,
                fontSize:   13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      glowColor: MindSyncColors.neonRed,
      showGlow: true,
      glowOpacity: 0.12,
      padding: const EdgeInsets.all(MindSyncDimensions.md),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
            size: 18, color: MindSyncColors.neonRed),
          const SizedBox(width: MindSyncDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color:    MindSyncColors.neonRed,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<AudioEngineBloc>().add(const AudioEngineStopRequested()),
            child: const Icon(Icons.close_rounded,
              size: 16, color: MindSyncColors.textMuted),
          ),
        ],
      ),
    );
  }
}
