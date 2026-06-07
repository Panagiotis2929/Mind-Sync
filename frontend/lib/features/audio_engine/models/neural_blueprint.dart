import 'package:equatable/equatable.dart';

/// OscillatorLayer represents a single synthesized frequency channel
/// as returned by the backend DSP engine.
class OscillatorLayer extends Equatable {
  final String id;
  final String mode;
  final double carrierFreqHz;
  final double beatFreqHz;
  final double leftChannelHz;
  final double rightChannelHz;
  final double amplitudeLinear;
  final double phaseOffsetRad;
  final String waveformType;

  const OscillatorLayer({
    required this.id,
    required this.mode,
    required this.carrierFreqHz,
    required this.beatFreqHz,
    required this.leftChannelHz,
    required this.rightChannelHz,
    required this.amplitudeLinear,
    required this.phaseOffsetRad,
    required this.waveformType,
  });

  factory OscillatorLayer.fromJson(Map<String, dynamic> json) {
    return OscillatorLayer(
      id:              json['id'] as String,
      mode:            json['mode'] as String,
      carrierFreqHz:   (json['carrier_freq_hz'] as num).toDouble(),
      beatFreqHz:      (json['beat_freq_hz'] as num).toDouble(),
      leftChannelHz:   (json['left_channel_hz'] as num).toDouble(),
      rightChannelHz:  (json['right_channel_hz'] as num).toDouble(),
      amplitudeLinear: (json['amplitude_linear'] as num).toDouble(),
      phaseOffsetRad:  (json['phase_offset_rad'] as num).toDouble(),
      waveformType:    json['waveform_type'] as String,
    );
  }

  @override
  List<Object?> get props => [
    id, mode, carrierFreqHz, beatFreqHz, leftChannelHz,
    rightChannelHz, amplitudeLinear, phaseOffsetRad, waveformType,
  ];
}

/// NoiseLayer specifies the spectral noise configuration.
class NoiseLayer extends Equatable {
  final String profile;
  final double amplitudeLinear;
  final double cutoffLowHz;
  final double cutoffHighHz;

  const NoiseLayer({
    required this.profile,
    required this.amplitudeLinear,
    required this.cutoffLowHz,
    required this.cutoffHighHz,
  });

  factory NoiseLayer.fromJson(Map<String, dynamic> json) {
    return NoiseLayer(
      profile:         json['profile'] as String,
      amplitudeLinear: (json['amplitude_linear'] as num).toDouble(),
      cutoffLowHz:     (json['cutoff_low_hz'] as num).toDouble(),
      cutoffHighHz:    (json['cutoff_high_hz'] as num).toDouble(),
    );
  }

  bool get isActive => profile != 'NONE' && amplitudeLinear > 0.001;

  @override
  List<Object?> get props => [profile, amplitudeLinear, cutoffLowHz, cutoffHighHz];
}

/// NeuralBlueprint is the immutable mathematical audio specification
/// computed by the backend and consumed by the frontend audio engine.
class NeuralBlueprint extends Equatable {
  final String id;
  final String sessionMode;
  final String brainwaveTarget;
  final int sampleRateHz;
  final int bitDepth;
  final double durationSec;
  final double fadeInSec;
  final double fadeOutSec;
  final List<OscillatorLayer> oscillators;
  final NoiseLayer noise;
  final double masterGainDb;
  final DateTime computedAt;
  final String checksum;

  const NeuralBlueprint({
    required this.id,
    required this.sessionMode,
    required this.brainwaveTarget,
    required this.sampleRateHz,
    required this.bitDepth,
    required this.durationSec,
    required this.fadeInSec,
    required this.fadeOutSec,
    required this.oscillators,
    required this.noise,
    required this.masterGainDb,
    required this.computedAt,
    required this.checksum,
  });

  factory NeuralBlueprint.fromJson(Map<String, dynamic> json) {
    return NeuralBlueprint(
      id:              json['id'] as String,
      sessionMode:     json['session_mode'] as String,
      brainwaveTarget: json['brainwave_target'] as String,
      sampleRateHz:    json['sample_rate_hz'] as int,
      bitDepth:        json['bit_depth'] as int,
      durationSec:     (json['duration_sec'] as num).toDouble(),
      fadeInSec:       (json['fade_in_sec'] as num).toDouble(),
      fadeOutSec:      (json['fade_out_sec'] as num).toDouble(),
      oscillators:     (json['oscillators'] as List)
          .map((o) => OscillatorLayer.fromJson(o as Map<String, dynamic>))
          .toList(),
      noise:           NoiseLayer.fromJson(json['noise'] as Map<String, dynamic>),
      masterGainDb:    (json['master_gain_db'] as num).toDouble(),
      computedAt:      DateTime.parse(json['computed_at'] as String),
      checksum:        json['checksum'] as String,
    );
  }

  /// primaryBeatHz returns the entrainment beat frequency of the first oscillator.
  double get primaryBeatHz => oscillators.isNotEmpty ? oscillators.first.beatFreqHz : 0;

  /// primaryCarrierHz returns the carrier frequency of the first oscillator.
  double get primaryCarrierHz => oscillators.isNotEmpty ? oscillators.first.carrierFreqHz : 200;

  @override
  List<Object?> get props => [id, checksum];
}
