// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:math' as math;
import 'dart:typed_data';
import '../models/neural_blueprint.dart';

/// WebAudioSynthesizer drives real-time audio synthesis using the browser's
/// Web Audio API via dart:js interop.
///
/// Audio graph architecture:
///   AudioContext
///     ├── OscillatorNode (left carrier)  ─┐
///     ├── OscillatorNode (right carrier) ─┤── StereoPannerNode ── GainNode (master) ── destination
///     ├── OscillatorNode (harmonic L)    ─┤
///     ├── OscillatorNode (harmonic R)    ─┘
///     └── BufferSourceNode (noise)  ── BiquadFilter(HPF) ── BiquadFilter(LPF) ── GainNode ──┘
///
/// The isochronic pulse is implemented via a GainNode amplitude-modulated
/// at the beat frequency using a secondary LFO OscillatorNode (square wave).
class WebAudioSynthesizer {
  js.JsObject? _audioContext;
  final List<js.JsObject> _oscillators = [];
  final List<js.JsObject> _gainNodes = [];
  js.JsObject? _masterGain;
  js.JsObject? _noiseNode;
  js.JsObject? _noiseGain;

  bool _isPlaying = false;
  // ignore: unused_field
  NeuralBlueprint? _currentBlueprint;

  bool get isPlaying => _isPlaying;

  // ── Public API ─────────────────────────────────────────────────────────

  /// start initializes the AudioContext and begins audio synthesis
  /// based on the provided NeuralBlueprint.
  Future<void> start(NeuralBlueprint blueprint) async {
    await stop(); // Tear down any previous synthesis graph
    _currentBlueprint = blueprint;

    // Create AudioContext (browsers require a user gesture first)
    _audioContext = js.JsObject(
      js.context['AudioContext'] ?? js.context['webkitAudioContext'],
    );

    final sampleRate = (_audioContext!['sampleRate'] as num).toDouble();
    final masterGainLinear = _dbToLinear(blueprint.masterGainDb);

    // ── Master gain node ──────────────────────────────────────────────
    _masterGain = _audioContext!.callMethod('createGain') as js.JsObject;
    _setAudioParam(_masterGain!, 'gain', 0.001); // Start silent for fade-in

    // Schedule fade-in via Web Audio API gain automation
    final now = (_audioContext!['currentTime'] as num).toDouble();
    (_masterGain!['gain'] as js.JsObject).callMethod('setValueAtTime', [0.001, now]);
    (_masterGain!['gain'] as js.JsObject).callMethod('linearRampToValueAtTime', [
      masterGainLinear,
      now + blueprint.fadeInSec,
    ]);

    _masterGain!.callMethod('connect', [_audioContext!['destination']]);

    // ── Build oscillator graph from blueprint layers ───────────────────
    for (final osc in blueprint.oscillators) {
      switch (osc.mode) {
        case 'BINAURAL':
        case 'SOLFEGGIO': // Solfeggio uses the same binaural stereo routing
          _buildBinauralPair(osc);
        case 'ISOCHRONIC':
          _buildIsochronicOscillator(osc);
      }
    }

    // ── Noise layer ───────────────────────────────────────────────────
    if (blueprint.noise.isActive) {
      _buildNoiseLayer(blueprint.noise, sampleRate);
    }

    _isPlaying = true;
  }

  /// updateBlueprint smoothly transitions to a new blueprint without
  /// clicks or pops, using Web Audio API parameter automation.
  Future<void> updateBlueprint(NeuralBlueprint blueprint) async {
    if (!_isPlaying || _audioContext == null) {
      await start(blueprint);
      return;
    }

    final now = (_audioContext!['currentTime'] as num).toDouble();
    const transitionTime = 0.05; // 50ms ramp — below audible click threshold

    // Update each oscillator frequency pair smoothly
    final minLayers = math.min(
      _oscillators.length ~/ 2,
      blueprint.oscillators.length,
    );
    for (var i = 0; i < minLayers; i++) {
      final osc = blueprint.oscillators[i];
      final leftOsc = _oscillators[i * 2];
      final rightOsc = _oscillators[i * 2 + 1];

      (leftOsc['frequency'] as js.JsObject).callMethod(
        'linearRampToValueAtTime',
        [osc.leftChannelHz, now + transitionTime],
      );
      (rightOsc['frequency'] as js.JsObject).callMethod(
        'linearRampToValueAtTime',
        [osc.rightChannelHz, now + transitionTime],
      );
    }

    // Update master gain
    final newGain = _dbToLinear(blueprint.masterGainDb);
    (_masterGain!['gain'] as js.JsObject).callMethod(
      'linearRampToValueAtTime',
      [newGain, now + transitionTime],
    );

    // Update noise gain if active
    if (_noiseGain != null && blueprint.noise.isActive) {
      (_noiseGain!['gain'] as js.JsObject).callMethod(
        'linearRampToValueAtTime',
        [blueprint.noise.amplitudeLinear, now + transitionTime],
      );
    }

    _currentBlueprint = blueprint;
  }

  /// stop gracefully fades out and disconnects all audio nodes.
  Future<void> stop() async {
    if (_audioContext == null) return;

    // Fade out master gain to avoid click on stop
    final now = (_audioContext!['currentTime'] as num).toDouble();
    if (_masterGain != null) {
      (_masterGain!['gain'] as js.JsObject).callMethod(
        'linearRampToValueAtTime',
        [0.0001, now + 0.3],
      );
    }

    // Wait for fade-out before disconnecting nodes
    await Future.delayed(const Duration(milliseconds: 350));

    for (final osc in _oscillators) {
      try {
        osc.callMethod('stop', []);
      } catch (_) {}
      try {
        osc.callMethod('disconnect', []);
      } catch (_) {}
    }
    _oscillators.clear();

    for (final gain in _gainNodes) {
      try {
        gain.callMethod('disconnect', []);
      } catch (_) {}
    }
    _gainNodes.clear();

    if (_noiseNode != null) {
      try {
        _noiseNode!.callMethod('disconnect', []);
      } catch (_) {}
      _noiseNode = null;
    }
    if (_noiseGain != null) {
      try {
        _noiseGain!.callMethod('disconnect', []);
      } catch (_) {}
      _noiseGain = null;
    }

    try {
      _audioContext!.callMethod('close', []);
    } catch (_) {}

    _audioContext = null;
    _masterGain = null;
    _isPlaying = false;
    _currentBlueprint = null;
  }

  // ── Private graph builders ─────────────────────────────────────────────

  /// Builds a stereo binaural pair: left ear at carrierHz, right ear at
  /// carrierHz + beatHz. The difference creates the binaural beat percept.
  void _buildBinauralPair(OscillatorLayer osc) {
    final leftOsc = _audioContext!.callMethod('createOscillator') as js.JsObject;
    final rightOsc = _audioContext!.callMethod('createOscillator') as js.JsObject;
    final leftPan = _audioContext!.callMethod('createStereoPanner') as js.JsObject;
    final rightPan = _audioContext!.callMethod('createStereoPanner') as js.JsObject;
    final gainNode = _audioContext!.callMethod('createGain') as js.JsObject;

    _setProperty(leftOsc, 'type', 'sine');
    _setProperty(rightOsc, 'type', 'sine');
    _setAudioParam(leftOsc, 'frequency', osc.leftChannelHz);
    _setAudioParam(rightOsc, 'frequency', osc.rightChannelHz);
    _setAudioParam(gainNode, 'gain', osc.amplitudeLinear);

    // Hard-pan: left oscillator fully left, right oscillator fully right
    final now = (_audioContext!['currentTime'] as num).toDouble();
    (leftPan['pan'] as js.JsObject).callMethod('setValueAtTime', [-1.0, now]);
    (rightPan['pan'] as js.JsObject).callMethod('setValueAtTime', [1.0, now]);

    // Graph: osc → panner → gain → master
    leftOsc.callMethod('connect', [leftPan]);
    rightOsc.callMethod('connect', [rightPan]);
    leftPan.callMethod('connect', [gainNode]);
    rightPan.callMethod('connect', [gainNode]);
    gainNode.callMethod('connect', [_masterGain!]);

    leftOsc.callMethod('start', []);
    rightOsc.callMethod('start', []);

    _oscillators.addAll([leftOsc, rightOsc]);
    _gainNodes.add(gainNode);
  }

  /// Builds a monaural isochronic oscillator: a carrier sine wave whose
  /// amplitude is modulated at the beat frequency by an LFO square wave.
  void _buildIsochronicOscillator(OscillatorLayer osc) {
    final carrier = _audioContext!.callMethod('createOscillator') as js.JsObject;
    final lfo = _audioContext!.callMethod('createOscillator') as js.JsObject;
    final lfoGain = _audioContext!.callMethod('createGain') as js.JsObject;
    final ampGain = _audioContext!.callMethod('createGain') as js.JsObject;

    _setProperty(carrier, 'type', 'sine');
    _setProperty(lfo, 'type', 'square'); // Hard on/off isochronic pulse
    _setAudioParam(carrier, 'frequency', osc.carrierFreqHz);
    _setAudioParam(lfo, 'frequency', osc.beatFreqHz);
    _setAudioParam(lfoGain, 'gain', osc.amplitudeLinear * 0.5);
    _setAudioParam(ampGain, 'gain', osc.amplitudeLinear * 0.5);

    // LFO → lfoGain → ampGain.gain (modulates carrier amplitude)
    lfo.callMethod('connect', [lfoGain]);
    lfoGain.callMethod('connect', [ampGain['gain']]);
    carrier.callMethod('connect', [ampGain]);
    ampGain.callMethod('connect', [_masterGain!]);

    carrier.callMethod('start', []);
    lfo.callMethod('start', []);

    _oscillators.addAll([carrier, lfo]);
    _gainNodes.addAll([lfoGain, ampGain]);
  }

  /// Builds the noise layer using a pre-computed Float32 buffer.
  /// Pink noise uses the Voss-McCartney algorithm (1/f approximation).
  /// Brown noise integrates white noise for a 1/f² (random walk) spectrum.
  void _buildNoiseLayer(NoiseLayer noise, double sampleRate) {
    final bufferSize = (sampleRate * 2).toInt(); // 2-second looping buffer
    final noiseBuffer = _audioContext!.callMethod(
      'createBuffer',
      [1, bufferSize, sampleRate.toInt()],
    ) as js.JsObject;

    // Build the PCM data in a typed Dart Float32List
    final data = Float32List(bufferSize);
    final rand = math.Random();

    if (noise.profile == 'PINK') {
      // Voss-McCartney 1/f pink noise algorithm
      var b0 = 0.0, b1 = 0.0, b2 = 0.0, b3 = 0.0, b4 = 0.0, b5 = 0.0;
      for (var i = 0; i < bufferSize; i++) {
        final white = rand.nextDouble() * 2 - 1;
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        data[i] = ((b0 + b1 + b2 + b3 + b4 + b5 + white * 0.5362) * 0.11)
            .clamp(-1.0, 1.0);
      }
    } else if (noise.profile == 'BROWN') {
      // Brownian (red) noise: random-walk integration of white noise
      var lastOut = 0.0;
      for (var i = 0; i < bufferSize; i++) {
        final white = rand.nextDouble() * 2 - 1;
        lastOut = (lastOut + 0.02 * white) / 1.02;
        data[i] = (lastOut * 3.5).clamp(-1.0, 1.0);
      }
    } else {
      // Pure white noise: uniform random samples
      for (var i = 0; i < bufferSize; i++) {
        data[i] = rand.nextDouble() * 2 - 1;
      }
    }

    // Transfer Float32List to the JS AudioBuffer via the Float32Array set() method
    final channelData = noiseBuffer.callMethod('getChannelData', [0]) as js.JsObject;
    channelData.callMethod('set', [js.JsArray.from(data)]);

    // BufferSourceNode in loop mode for infinite playback
    _noiseNode = _audioContext!.callMethod('createBufferSource') as js.JsObject;
    _noiseNode!['buffer'] = noiseBuffer;
    _noiseNode!['loop'] = true;

    // Spectral shaping: HPF removes sub-bass rumble, LPF removes hiss
    final hpf = _audioContext!.callMethod('createBiquadFilter') as js.JsObject;
    final lpf = _audioContext!.callMethod('createBiquadFilter') as js.JsObject;

    _setProperty(hpf, 'type', 'highpass');
    _setProperty(lpf, 'type', 'lowpass');
    _setAudioParam(hpf, 'frequency', noise.cutoffLowHz);
    _setAudioParam(lpf, 'frequency', noise.cutoffHighHz);

    _noiseGain = _audioContext!.callMethod('createGain') as js.JsObject;
    _setAudioParam(_noiseGain!, 'gain', noise.amplitudeLinear);

    // Graph: noiseNode → HPF → LPF → noiseGain → master
    _noiseNode!.callMethod('connect', [hpf]);
    hpf.callMethod('connect', [lpf]);
    lpf.callMethod('connect', [_noiseGain!]);
    _noiseGain!.callMethod('connect', [_masterGain!]);
    _noiseNode!.callMethod('start', []);
  }

  // ── Web Audio API helpers ──────────────────────────────────────────────

  /// Sets a plain JS property on a JsObject node (e.g. oscillator.type).
  void _setProperty(js.JsObject node, String property, dynamic value) {
    node[property] = value;
  }

  /// Sets the .value of a Web Audio AudioParam AudioNode sub-property.
  /// e.g. oscillator.frequency.value = 440
  void _setAudioParam(js.JsObject node, String param, double value) {
    (node[param] as js.JsObject)['value'] = value;
  }

  /// Converts a dBFS value to a linear amplitude multiplier.
  /// Formula: linear = 10^(dB/20)
  double _dbToLinear(double db) => math.pow(10.0, db / 20.0).toDouble();
}
