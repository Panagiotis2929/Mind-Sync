import 'package:equatable/equatable.dart';

/// SessionMode represents the four operating modes of Mind-Sync.
enum SessionMode {
  focus('FOCUS', 'Focus', 'Deep work & cognitive performance'),
  sleep('SLEEP', 'Sleep', 'Restorative rest & dreams'),
  creative('CREATIVE', 'Creative', 'Inspiration & flow state'),
  custom('CUSTOM', 'Custom', 'Manual frequency tuning');

  const SessionMode(this.apiValue, this.label, this.description);
  final String apiValue;
  final String label;
  final String description;
}

/// NoiseProfileMode maps to backend noise options.
enum NoiseProfileMode {
  none('NONE', 'Off'),
  white('WHITE', 'White'),
  pink('PINK', 'Pink'),
  brown('BROWN', 'Brown');

  const NoiseProfileMode(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// OscillatorModeType maps to backend oscillator modes.
enum OscillatorModeType {
  binaural('BINAURAL', 'Binaural'),
  isochronic('ISOCHRONIC', 'Isochronic'),
  solfeggio('SOLFEGGIO', 'Solfeggio');

  const OscillatorModeType(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// SynthesisParameters is the immutable state of all user-controlled sliders.
/// This is what gets serialized and sent to the backend blueprint engine.
class SynthesisParameters extends Equatable {
  final SessionMode sessionMode;
  final double focusDepth;      // 0.0 – 1.0
  final double calmLevel;       // 0.0 – 1.0
  final double energyLevel;     // 0.0 – 1.0
  final NoiseProfileMode noiseProfile;
  final double noiseVolume;     // 0.0 – 1.0
  final OscillatorModeType oscillatorMode;
  final double masterVolume;    // 0.0 – 1.0
  final double durationSec;     // 0 = loop

  const SynthesisParameters({
    this.sessionMode    = SessionMode.focus,
    this.focusDepth     = 0.70,
    this.calmLevel      = 0.40,
    this.energyLevel    = 0.65,
    this.noiseProfile   = NoiseProfileMode.pink,
    this.noiseVolume    = 0.25,
    this.oscillatorMode = OscillatorModeType.binaural,
    this.masterVolume   = 0.70,
    this.durationSec    = 0.0,
  });

  SynthesisParameters copyWith({
    SessionMode? sessionMode,
    double? focusDepth,
    double? calmLevel,
    double? energyLevel,
    NoiseProfileMode? noiseProfile,
    double? noiseVolume,
    OscillatorModeType? oscillatorMode,
    double? masterVolume,
    double? durationSec,
  }) {
    return SynthesisParameters(
      sessionMode:    sessionMode    ?? this.sessionMode,
      focusDepth:     focusDepth     ?? this.focusDepth,
      calmLevel:      calmLevel      ?? this.calmLevel,
      energyLevel:    energyLevel    ?? this.energyLevel,
      noiseProfile:   noiseProfile   ?? this.noiseProfile,
      noiseVolume:    noiseVolume    ?? this.noiseVolume,
      oscillatorMode: oscillatorMode ?? this.oscillatorMode,
      masterVolume:   masterVolume   ?? this.masterVolume,
      durationSec:    durationSec    ?? this.durationSec,
    );
  }

  /// toApiJson serializes this model to the backend DTO format.
  Map<String, dynamic> toApiJson() {
    return {
      'session_mode':    sessionMode.apiValue,
      'focus_depth':     focusDepth,
      'calm_level':      calmLevel,
      'energy_level':    energyLevel,
      'noise_profile':   noiseProfile.apiValue,
      'noise_volume':    noiseVolume,
      'oscillator_mode': oscillatorMode.apiValue,
      'master_volume':   masterVolume,
      'duration_sec':    durationSec,
    };
  }

  @override
  List<Object?> get props => [
    sessionMode, focusDepth, calmLevel, energyLevel,
    noiseProfile, noiseVolume, oscillatorMode, masterVolume, durationSec,
  ];
}
