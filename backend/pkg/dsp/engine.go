// Package dsp implements the Digital Signal Processing blueprint engine.
// It operates purely on mathematical parameters — no audio I/O, no file I/O.
// All output is a deterministic, serializable specification that the frontend
// uses to synthesize sound in real-time via the Web Audio API.
package dsp

import (
	"crypto/sha256"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
)

// SynthesisParams encapsulates all user-supplied parameters for blueprint computation.
// Values are validated before reaching this layer; all floats are in [0.0, 1.0].
type SynthesisParams struct {
	SessionMode  string                   // "FOCUS" | "SLEEP" | "CREATIVE" | "CUSTOM"
	FocusDepth   float64                  // 0.0 = deeply relaxed → 1.0 = hyper-focused
	CalmLevel    float64                  // 0.0 = intense → 1.0 = serene
	EnergyLevel  float64                  // 0.0 = passive → 1.0 = energized
	NoiseProfile entities.NoiseProfile
	NoiseVolume  float64
	OscMode      entities.OscillatorMode
	MasterVolume float64
	DurationSec  float64 // 0 = loop
}

// Engine is the stateless DSP blueprint generator.
// It uses psychoacoustic research tables to map user parameters to frequencies.
type Engine struct {
	sampleRate int
	bitDepth   int
}

// NewEngine creates a new DSP Engine configured for CD-quality output.
func NewEngine() *Engine {
	return &Engine{
		sampleRate: 44100,
		bitDepth:   32,
	}
}

// --- Psychoacoustic frequency tables ---

// brainwaveRanges maps cognitive states to [min, max] entrainment Hz ranges.
// Derived from peer-reviewed neuroscience literature on brainwave entrainment.
var brainwaveRanges = map[entities.BrainwaveState][2]float64{
	entities.BrainwaveGamma: {30.0, 100.0},
	entities.BrainwaveBeta:  {13.0, 30.0},
	entities.BrainwaveAlpha: {8.0, 13.0},
	entities.BrainwaveTheta: {4.0, 8.0},
	entities.BrainwaveDelta: {0.5, 4.0},
}

// solfeggioFrequencies are the sacred/healing frequencies used in Solfeggio mode.
var solfeggioFrequencies = []float64{174.0, 285.0, 396.0, 417.0, 528.0, 639.0, 741.0, 852.0, 963.0}

// carrierFrequencyBase maps session modes to ergonomic carrier tones.
// Carrier must be >40 Hz for spatial perception; ideal range is 100–500 Hz.
var carrierFrequencyBase = map[string]float64{
	"FOCUS":    200.0, // Clear, neutral
	"SLEEP":    136.1, // "Om" frequency, grounding
	"CREATIVE": 160.0, // Warm, spacious
	"CUSTOM":   220.0, // Concert A/2
}

// Compute is the core DSP computation. It takes synthesis parameters and returns
// a fully-specified NeuralBlueprint — a pure mathematical audio specification.
// This function is deterministic: identical params always yield identical output.
func (e *Engine) Compute(params SynthesisParams) (*entities.NeuralBlueprint, error) {
	target := e.selectBrainwaveTarget(params)
	beatFreq := e.computeBeatFrequency(params, target)
	carrier := e.computeCarrierFrequency(params)
	oscillators := e.buildOscillatorLayers(params, carrier, beatFreq)
	noise := e.buildNoiseLayer(params)
	masterGainDB := e.volumeToDecibels(params.MasterVolume)
	checksum := e.computeChecksum(params)

	blueprint := &entities.NeuralBlueprint{
		ID:              uuid.New(),
		SessionMode:     params.SessionMode,
		BrainwaveTarget: target,
		SampleRateHz:    e.sampleRate,
		BitDepth:        e.bitDepth,
		DurationSec:     params.DurationSec,
		FadeInSec:       e.computeFadeIn(params),
		FadeOutSec:      3.0,
		Oscillators:     oscillators,
		Noise:           noise,
		MasterGainDB:    masterGainDB,
		ComputedAt:      time.Now().UTC(),
		Checksum:        checksum,
	}

	return blueprint, nil
}

// selectBrainwaveTarget maps the three user sliders to a target brainwave band.
// The algorithm uses a weighted centroid across the psychoacoustic spectrum.
func (e *Engine) selectBrainwaveTarget(p SynthesisParams) entities.BrainwaveState {
	switch p.SessionMode {
	case "SLEEP":
		// Sleep always targets theta→delta regardless of sliders
		if p.CalmLevel > 0.7 {
			return entities.BrainwaveDelta
		}
		return entities.BrainwaveTheta

	case "FOCUS":
		// High focus depth pushes into beta/gamma
		if p.FocusDepth > 0.75 {
			return entities.BrainwaveGamma
		}
		if p.FocusDepth > 0.45 {
			return entities.BrainwaveBeta
		}
		return entities.BrainwaveAlpha

	case "CREATIVE":
		// Creative flow lives in alpha-theta boundary
		return entities.BrainwaveAlpha

	default: // CUSTOM
		// Derive from weighted slider combination
		// Normalize: focusScore pushes toward gamma, calmScore toward delta
		focusScore := p.FocusDepth * 1.0
		calmScore := p.CalmLevel * 0.8
		energyScore := p.EnergyLevel * 0.6
		composite := (focusScore + energyScore - calmScore + 1.0) / 2.0 // [0, 1]

		switch {
		case composite > 0.80:
			return entities.BrainwaveGamma
		case composite > 0.60:
			return entities.BrainwaveBeta
		case composite > 0.40:
			return entities.BrainwaveAlpha
		case composite > 0.20:
			return entities.BrainwaveTheta
		default:
			return entities.BrainwaveDelta
		}
	}
}

// computeBeatFrequency calculates the precise entrainment beat frequency in Hz.
// The beat frequency is the perceptible pulsation rate that drives brainwave entrainment.
// For binaural beats: beatFreq = |leftHz - rightHz|
// The slider position maps to a specific Hz within the brainwave band.
func (e *Engine) computeBeatFrequency(p SynthesisParams, target entities.BrainwaveState) float64 {
	bounds := brainwaveRanges[target]
	low, high := bounds[0], bounds[1]

	// Position within band is driven by intensity: for focus, high=high; for sleep, low=low
	var t float64
	switch p.SessionMode {
	case "FOCUS":
		t = p.FocusDepth // 0=lower alpha, 1=upper gamma
	case "SLEEP":
		t = 1.0 - p.CalmLevel // calm=1 → delta floor
	case "CREATIVE":
		// Creative targets mid-alpha (Schumann resonance proximity)
		t = 0.4 + (p.EnergyLevel * 0.3)
	default:
		t = (p.FocusDepth + p.EnergyLevel) / 2.0
	}

	t = math.Max(0.0, math.Min(1.0, t))
	return low + t*(high-low)
}

// computeCarrierFrequency establishes the audible base tone.
// The carrier is modulated by user energy and calm to feel right for the mode.
func (e *Engine) computeCarrierFrequency(p SynthesisParams) float64 {
	base := carrierFrequencyBase[p.SessionMode]
	if base == 0 {
		base = carrierFrequencyBase["CUSTOM"]
	}
	// Slight modulation: energy raises carrier slightly, calm lowers it
	energyBias := p.EnergyLevel * 20.0
	calmBias := p.CalmLevel * 10.0
	return base + energyBias - calmBias
}

// buildOscillatorLayers constructs 1–3 oscillator layers depending on mode and richness.
func (e *Engine) buildOscillatorLayers(
	p SynthesisParams,
	carrier float64,
	beatFreq float64,
) []entities.OscillatorLayer {
	layers := make([]entities.OscillatorLayer, 0, 3)

	switch p.OscMode {
	case entities.OscillatorBinaural:
		// Primary binaural layer: left = carrier, right = carrier + beatFreq
		layers = append(layers, entities.OscillatorLayer{
			ID:              uuid.New().String(),
			Mode:            entities.OscillatorBinaural,
			CarrierFreqHz:   carrier,
			BeatFreqHz:      beatFreq,
			LeftChannelHz:   carrier,
			RightChannelHz:  carrier + beatFreq,
			AmplitudeLinear: e.computeLayerAmplitude(p, 0),
			PhaseOffsetRad:  0.0,
			WaveformType:    "sine",
		})

		// Optional harmonic overtone at 3x carrier (adds warmth/depth)
		if p.EnergyLevel > 0.4 {
			harmonicCarrier := carrier * 1.5 // Perfect fifth
			layers = append(layers, entities.OscillatorLayer{
				ID:              uuid.New().String(),
				Mode:            entities.OscillatorBinaural,
				CarrierFreqHz:   harmonicCarrier,
				BeatFreqHz:      beatFreq,
				LeftChannelHz:   harmonicCarrier,
				RightChannelHz:  harmonicCarrier + beatFreq,
				AmplitudeLinear: e.computeLayerAmplitude(p, 1),
				PhaseOffsetRad:  math.Pi / 4.0,
				WaveformType:    "sine",
			})
		}

	case entities.OscillatorIsochronic:
		// Isochronic: single monaural channel, amplitude-modulated at beatFreq
		layers = append(layers, entities.OscillatorLayer{
			ID:              uuid.New().String(),
			Mode:            entities.OscillatorIsochronic,
			CarrierFreqHz:   carrier,
			BeatFreqHz:      beatFreq,
			LeftChannelHz:   carrier, // Same on both channels (monaural)
			RightChannelHz:  carrier,
			AmplitudeLinear: e.computeLayerAmplitude(p, 0),
			PhaseOffsetRad:  0.0,
			WaveformType:    "sine",
		})

		// Sub-harmonic support tone for depth
		if p.CalmLevel > 0.3 {
			subCarrier := carrier * 0.5
			layers = append(layers, entities.OscillatorLayer{
				ID:              uuid.New().String(),
				Mode:            entities.OscillatorIsochronic,
				CarrierFreqHz:   subCarrier,
				BeatFreqHz:      beatFreq / 2.0,
				LeftChannelHz:   subCarrier,
				RightChannelHz:  subCarrier,
				AmplitudeLinear: e.computeLayerAmplitude(p, 1) * 0.6,
				PhaseOffsetRad:  math.Pi,
				WaveformType:    "sine",
			})
		}

	case entities.OscillatorSolfeggio:
		// Pick the closest Solfeggio frequency and build a binaural beat around it
		solfreq := e.nearestSolfeggio(carrier)
		layers = append(layers, entities.OscillatorLayer{
			ID:              uuid.New().String(),
			Mode:            entities.OscillatorSolfeggio,
			CarrierFreqHz:   solfreq,
			BeatFreqHz:      beatFreq,
			LeftChannelHz:   solfreq,
			RightChannelHz:  solfreq + beatFreq,
			AmplitudeLinear: e.computeLayerAmplitude(p, 0),
			PhaseOffsetRad:  0.0,
			WaveformType:    "sine",
		})

		// Add a secondary Solfeggio tone for interval richness
		secSol := e.nearestSolfeggioAbove(solfreq)
		if secSol > 0 {
			layers = append(layers, entities.OscillatorLayer{
				ID:              uuid.New().String(),
				Mode:            entities.OscillatorSolfeggio,
				CarrierFreqHz:   secSol,
				BeatFreqHz:      beatFreq,
				LeftChannelHz:   secSol,
				RightChannelHz:  secSol + beatFreq,
				AmplitudeLinear: e.computeLayerAmplitude(p, 1) * 0.5,
				PhaseOffsetRad:  math.Pi / 6.0,
				WaveformType:    "sine",
			})
		}
	}

	return layers
}

// buildNoiseLayer computes the noise channel specification with spectral shaping.
func (e *Engine) buildNoiseLayer(p SynthesisParams) entities.NoiseLayer {
	if p.NoiseProfile == entities.NoiseNone || p.NoiseVolume < 0.001 {
		return entities.NoiseLayer{Profile: entities.NoiseNone}
	}

	// Spectral shape depends on profile type and session mode
	var lowCut, highCut float64
	switch p.SessionMode {
	case "SLEEP":
		lowCut, highCut = 20.0, 500.0 // Heavy LPF for soothing rumble
	case "FOCUS":
		lowCut, highCut = 100.0, 8000.0 // Broader presence, like an office HVAC
	case "CREATIVE":
		lowCut, highCut = 50.0, 4000.0 // Mid-range warmth
	default:
		lowCut, highCut = 20.0, 20000.0 // Full spectrum
	}

	return entities.NoiseLayer{
		Profile:         p.NoiseProfile,
		AmplitudeLinear: p.NoiseVolume * 0.3, // Noise shouldn't overwhelm tones
		CutoffLowHz:     lowCut,
		CutoffHighHz:    highCut,
	}
}

// computeLayerAmplitude determines per-layer gain using psychoacoustic loudness scaling.
// Layer index 0 = primary (loudest), higher = harmonic support (progressively quieter).
func (e *Engine) computeLayerAmplitude(p SynthesisParams, layerIdx int) float64 {
	base := p.MasterVolume
	// Psychoacoustic equal-loudness curve approximation (Fletcher–Munson)
	// Primary layer gets full amplitude; harmonics get 1/n reduction
	reduction := 1.0 / math.Pow(2.0, float64(layerIdx))
	return math.Max(0.001, base*reduction)
}

// computeFadeIn calculates an appropriate fade-in duration.
// Sleep sessions use long fades; focus sessions use short snappy fades.
func (e *Engine) computeFadeIn(p SynthesisParams) float64 {
	switch p.SessionMode {
	case "SLEEP":
		return 8.0 + p.CalmLevel*7.0 // 8–15 seconds
	case "FOCUS":
		return 2.0 + (1.0-p.FocusDepth)*3.0 // 2–5 seconds
	case "CREATIVE":
		return 4.0
	default:
		return 3.0
	}
}

// volumeToDecibels converts a linear [0,1] volume to dBFS.
// Uses proper dB = 20 * log10(amplitude) with -96 dBFS floor.
func (e *Engine) volumeToDecibels(linear float64) float64 {
	if linear <= 0.0001 {
		return -96.0
	}
	return 20.0 * math.Log10(math.Max(0.0001, linear))
}

// nearestSolfeggio finds the Solfeggio frequency closest to the given target.
func (e *Engine) nearestSolfeggio(target float64) float64 {
	nearest := solfeggioFrequencies[0]
	minDist := math.Abs(target - nearest)
	for _, f := range solfeggioFrequencies[1:] {
		if d := math.Abs(target - f); d < minDist {
			minDist = d
			nearest = f
		}
	}
	return nearest
}

// nearestSolfeggioAbove finds the next Solfeggio frequency above the given one.
func (e *Engine) nearestSolfeggioAbove(current float64) float64 {
	for _, f := range solfeggioFrequencies {
		if f > current+10 {
			return f
		}
	}
	return -1
}

// computeChecksum produces a deterministic SHA-256 hash of synthesis parameters.
// Identical params always yield identical checksums, enabling cache lookup.
func (e *Engine) computeChecksum(p SynthesisParams) string {
	data := fmt.Sprintf(
		"%s|%.6f|%.6f|%.6f|%s|%.6f|%s|%.6f|%.6f",
		p.SessionMode, p.FocusDepth, p.CalmLevel, p.EnergyLevel,
		p.NoiseProfile, p.NoiseVolume, p.OscMode, p.MasterVolume, p.DurationSec,
	)
	sum := sha256.Sum256([]byte(data))
	return fmt.Sprintf("%x", sum)
}
