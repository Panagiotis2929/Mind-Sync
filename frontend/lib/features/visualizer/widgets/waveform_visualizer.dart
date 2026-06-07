import 'package:flutter/material.dart';
import '../../audio_engine/models/neural_blueprint.dart';
import '../painters/waveform_painter.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';

/// WaveformVisualizer is a self-animating widget that renders the real-time
/// audio waveform using [WaveformPainter].
///
/// It owns an [AnimationController] that drives the wave phase at a rate
/// proportional to the active blueprint's beat frequency, creating a
/// perceptually accurate animation speed.
class WaveformVisualizer extends StatefulWidget {
  final NeuralBlueprint? blueprint;
  final bool isPlaying;
  final double height;

  const WaveformVisualizer({
    super.key,
    required this.blueprint,
    required this.isPlaying,
    this.height = MindSyncDimensions.visualizerHeight,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _computeCycleDuration(),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation speed when blueprint changes (beat frequency changes)
    if (oldWidget.blueprint != widget.blueprint) {
      _controller.duration = _computeCycleDuration();
      if (widget.isPlaying && !_controller.isAnimating) {
        _controller.repeat();
      }
    }

    // Start or stop based on playback state
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 800));
      }
    }
  }

  /// Animation duration is inversely proportional to beat frequency.
  /// Higher beat Hz → faster wave phase cycling (more cycles per second).
  Duration _computeCycleDuration() {
    if (widget.blueprint == null || widget.blueprint!.oscillators.isEmpty) {
      return const Duration(seconds: 4); // Idle: slow gentle wave
    }
    final beatHz = widget.blueprint!.primaryBeatHz.clamp(0.5, 40.0);
    // One animation cycle = one full beat period
    // We slow it down by 3x for visual clarity (would be too fast otherwise)
    final ms = (3000 / beatHz).round().clamp(200, 8000);
    return Duration(milliseconds: ms);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brainwave = widget.blueprint?.brainwaveTarget ?? 'ALPHA';
    final primaryColor   = MindSyncColors.forBrainwave(brainwave);
    final secondaryColor = MindSyncColors.neonPurple;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: MindSyncColors.backgroundCard,
        borderRadius: BorderRadius.circular(MindSyncDimensions.radiusMd),
        border: Border.all(
          color: primaryColor.withOpacity(widget.isPlaying ? 0.4 : 0.15),
          width: 1.0,
        ),
        boxShadow: widget.isPlaying
            ? [
                BoxShadow(
                  color:       primaryColor.withOpacity(0.12),
                  blurRadius:  MindSyncDimensions.glowBlurRadius,
                  spreadRadius: MindSyncDimensions.glowSpread,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MindSyncDimensions.radiusMd),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: WaveformPainter(
                blueprint:      widget.blueprint,
                animationValue: _controller.value,
                primaryColor:   primaryColor,
                secondaryColor: secondaryColor,
                showGrid:       true,
                showLabels:     widget.blueprint != null,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}
