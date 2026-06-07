import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/neural_blueprint.dart';
import '../models/synthesis_parameters.dart';
import '../services/api_client.dart';
import '../services/web_audio_synthesizer.dart';

part 'audio_engine_event.dart';
part 'audio_engine_state.dart';

/// AudioEngineBloc is the central state machine for all audio operations.
///
/// Event flow:
///   ParametersChanged → debounce(350ms) → computeBlueprint() → updateSynthesizer()
///   StartRequested    → computeBlueprint() → startSynthesizer() → startSession()
///   StopRequested     → stopSynthesizer() → finalizeSession()
///
/// The debounce on parameter changes prevents flooding the backend with
/// requests while the user is dragging a slider.
class AudioEngineBloc extends Bloc<AudioEngineEvent, AudioEngineState> {
  final MindSyncApiClient _api;
  final WebAudioSynthesizer _synth;

  // Debounce timer for live parameter changes during playback
  Timer? _paramDebounce;

  // Session elapsed time ticker
  Timer? _sessionTicker;
  DateTime? _sessionStart;

  AudioEngineBloc({
    required MindSyncApiClient api,
    required WebAudioSynthesizer synth,
  })  : _api = api,
        _synth = synth,
        super(const AudioEngineState()) {
    on<AudioEngineStartRequested>(_onStartRequested);
    on<AudioEngineStopRequested>(_onStopRequested);
    on<AudioEngineParametersChanged>(_onParametersChanged);
    on<AudioEnginePresetLoaded>(_onPresetLoaded);
    on<AudioEngineHealthChecked>(_onHealthChecked);

    // Check backend health on bloc creation
    _checkHealth();
  }

  // ── Event handlers ─────────────────────────────────────────────────────

  Future<void> _onStartRequested(
    AudioEngineStartRequested event,
    Emitter<AudioEngineState> emit,
  ) async {
    if (state.isPlaying) return;

    emit(state.copyWith(status: PlaybackStatus.computing, clearError: true));

    try {
      // 1. Compute blueprint from current parameters
      final blueprint = await _api.computeBlueprint(state.parameters);

      // 2. Start audio synthesis
      await _synth.start(blueprint);

      // 3. Start session record in backend
      String? sessionId;
      try {
        final session = await _api.startSession({
          'blueprint_id': blueprint.id,
          'session_mode': blueprint.sessionMode,
        });
        sessionId = session['id'] as String?;
      } catch (e) {
        // Non-fatal: session tracking failure doesn't stop audio
        debugPrint('Session tracking unavailable: $e');
      }

      // 4. Start elapsed time ticker
      _sessionStart = DateTime.now();
      _sessionTicker?.cancel();
      _sessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.isPlaying) {
          final elapsed = DateTime.now().difference(_sessionStart!).inSeconds.toDouble();
          emit(state.copyWith(sessionElapsedSec: elapsed));
        }
      });

      emit(state.copyWith(
        status:           PlaybackStatus.playing,
        activeBlueprint:  blueprint,
        activeSessionId:  sessionId,
        sessionElapsedSec: 0.0,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status:       PlaybackStatus.error,
        errorMessage: 'Backend error: ${e.message}',
      ));
    } catch (e) {
      emit(state.copyWith(
        status:       PlaybackStatus.error,
        errorMessage: 'Failed to start audio: $e',
      ));
    }
  }

  Future<void> _onStopRequested(
    AudioEngineStopRequested event,
    Emitter<AudioEngineState> emit,
  ) async {
    if (!state.isPlaying) return;

    emit(state.copyWith(status: PlaybackStatus.stopping));
    _paramDebounce?.cancel();
    _sessionTicker?.cancel();

    // 1. Stop audio (includes fade-out)
    await _synth.stop();

    // 2. Finalize session record
    if (state.activeSessionId != null) {
      final elapsed = state.sessionElapsedSec;
      try {
        await _api.finalizeSession(state.activeSessionId!, elapsed);
      } catch (e) {
        debugPrint('Failed to finalize session: $e');
      }
    }

    emit(state.copyWith(
      status:          PlaybackStatus.idle,
      clearSessionId:  true,
      sessionElapsedSec: 0.0,
    ));
  }

  Future<void> _onParametersChanged(
    AudioEngineParametersChanged event,
    Emitter<AudioEngineState> emit,
  ) async {
    // Always update the parameter state immediately (for UI feedback)
    emit(state.copyWith(parameters: event.parameters));

    // If playing, debounce the DSP recomputation to avoid request flooding
    if (state.isPlaying) {
      _paramDebounce?.cancel();
      _paramDebounce = Timer(const Duration(milliseconds: 350), () {
        _recomputeAndUpdate(event.parameters);
      });
    }
  }

  Future<void> _onPresetLoaded(
    AudioEnginePresetLoaded event,
    Emitter<AudioEngineState> emit,
  ) async {
    emit(state.copyWith(parameters: event.parameters));

    // If currently playing, immediately recompute and update synthesis
    if (state.isPlaying) {
      await _recomputeAndUpdate(event.parameters);
    }
  }

  void _onHealthChecked(
    AudioEngineHealthChecked event,
    Emitter<AudioEngineState> emit,
  ) {
    emit(state.copyWith(isBackendReachable: event.isBackendReachable));
  }

  // ── Private helpers ────────────────────────────────────────────────────

  /// Recomputes a blueprint and smoothly updates the running synthesizer.
  Future<void> _recomputeAndUpdate(SynthesisParameters params) async {
    try {
      final blueprint = await _api.computeBlueprint(params);
      await _synth.updateBlueprint(blueprint);

      // Emit the new blueprint so the waveform visualizer updates
      if (!isClosed) {
        emit(state.copyWith(activeBlueprint: blueprint));
      }
    } on ApiException catch (e) {
      debugPrint('Live recompute failed: ${e.message}');
      // Non-fatal during live update — don't interrupt playback
    } catch (e) {
      debugPrint('Live recompute error: $e');
    }
  }

  Future<void> _checkHealth() async {
    final reachable = await _api.checkHealth();
    if (!isClosed) {
      add(AudioEngineHealthChecked(reachable));
    }
  }

  @override
  Future<void> close() {
    _paramDebounce?.cancel();
    _sessionTicker?.cancel();
    _synth.stop();
    return super.close();
  }
}
