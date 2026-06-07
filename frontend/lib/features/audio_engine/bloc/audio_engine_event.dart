part of 'audio_engine_bloc.dart';

/// AudioEngineEvent is the sealed event hierarchy for the audio engine BLoC.
@immutable
sealed class AudioEngineEvent extends Equatable {
  const AudioEngineEvent();
}

/// Fired when the user presses Play.
final class AudioEngineStartRequested extends AudioEngineEvent {
  const AudioEngineStartRequested();
  @override List<Object?> get props => [];
}

/// Fired when the user presses Stop.
final class AudioEngineStopRequested extends AudioEngineEvent {
  const AudioEngineStopRequested();
  @override List<Object?> get props => [];
}

/// Fired whenever any synthesis parameter slider changes.
final class AudioEngineParametersChanged extends AudioEngineEvent {
  final SynthesisParameters parameters;
  const AudioEngineParametersChanged(this.parameters);
  @override List<Object?> get props => [parameters];
}

/// Fired when a factory preset or saved signature is loaded.
final class AudioEnginePresetLoaded extends AudioEngineEvent {
  final SynthesisParameters parameters;
  const AudioEnginePresetLoaded(this.parameters);
  @override List<Object?> get props => [parameters];
}

/// Fired when the backend health check completes.
final class AudioEngineHealthChecked extends AudioEngineEvent {
  final bool isBackendReachable;
  const AudioEngineHealthChecked(this.isBackendReachable);
  @override List<Object?> get props => [isBackendReachable];
}
