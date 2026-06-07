part of 'audio_engine_bloc.dart';

/// PlaybackStatus represents the lifecycle state of the audio engine.
enum PlaybackStatus {
  idle,       // No audio playing, no pending operations
  computing,  // Awaiting blueprint from backend DSP engine
  playing,    // Audio actively synthesizing
  stopping,   // Fade-out in progress
  error,      // Unrecoverable failure
}

/// AudioEngineState is the immutable state snapshot of the audio system.
@immutable
final class AudioEngineState extends Equatable {
  final PlaybackStatus status;
  final SynthesisParameters parameters;
  final NeuralBlueprint? activeBlueprint;
  final String? errorMessage;
  final bool isBackendReachable;
  final String? activeSessionId;  // Non-null while a session is being recorded
  final double sessionElapsedSec;

  const AudioEngineState({
    this.status              = PlaybackStatus.idle,
    this.parameters          = const SynthesisParameters(),
    this.activeBlueprint     = null,
    this.errorMessage        = null,
    this.isBackendReachable  = true,
    this.activeSessionId     = null,
    this.sessionElapsedSec   = 0.0,
  });

  bool get isPlaying   => status == PlaybackStatus.playing;
  bool get isComputing => status == PlaybackStatus.computing;
  bool get hasError    => status == PlaybackStatus.error;

  AudioEngineState copyWith({
    PlaybackStatus? status,
    SynthesisParameters? parameters,
    NeuralBlueprint? activeBlueprint,
    String? errorMessage,
    bool? isBackendReachable,
    String? activeSessionId,
    double? sessionElapsedSec,
    bool clearBlueprint    = false,
    bool clearError        = false,
    bool clearSessionId    = false,
  }) {
    return AudioEngineState(
      status:             status             ?? this.status,
      parameters:         parameters         ?? this.parameters,
      activeBlueprint:    clearBlueprint ? null : (activeBlueprint ?? this.activeBlueprint),
      errorMessage:       clearError    ? null : (errorMessage    ?? this.errorMessage),
      isBackendReachable: isBackendReachable ?? this.isBackendReachable,
      activeSessionId:    clearSessionId ? null : (activeSessionId ?? this.activeSessionId),
      sessionElapsedSec:  sessionElapsedSec  ?? this.sessionElapsedSec,
    );
  }

  @override
  List<Object?> get props => [
    status, parameters, activeBlueprint, errorMessage,
    isBackendReachable, activeSessionId, sessionElapsedSec,
  ];
}
