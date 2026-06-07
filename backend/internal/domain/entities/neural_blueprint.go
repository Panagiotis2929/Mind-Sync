package entities

import (
	"time"

	"github.com/google/uuid"
)

// BrainwaveState represents the target neural oscillation band.
type BrainwaveState string

const (
	BrainwaveGamma BrainwaveState = "GAMMA"  // 30–100 Hz  – Peak focus, cognitive performance
	BrainwaveBeta  BrainwaveState = "BETA"   // 13–30 Hz   – Active thinking, alertness
	BrainwaveAlpha BrainwaveState = "ALPHA"  // 8–13 Hz    – Relaxed focus, creativity
	BrainwaveTheta BrainwaveState = "THETA"  // 4–8 Hz     – Deep meditation, REM sleep
	BrainwaveDelta BrainwaveState = "DELTA"  // 0.5–4 Hz   – Deep dreamless sleep, healing
)

// OscillatorMode determines how the beat frequency entrains the brain.
type OscillatorMode string

const (
	OscillatorBinaural   OscillatorMode = "BINAURAL"    // Two slightly different frequencies per ear
	OscillatorIsochronic OscillatorMode = "ISOCHRONIC"  // Monaural pulsing at exact beat frequency
	OscillatorSolfeggio  OscillatorMode = "SOLFEGGIO"   // Sacred Hz tones (396, 417, 528…)
)

// NoiseProfile defines the spectral density of additive noise.
type NoiseProfile string

const (
	NoiseNone  NoiseProfile = "NONE"
	NoiseWhite NoiseProfile = "WHITE" // Equal power per Hz (flat PSD)
	NoisePink  NoiseProfile = "PINK"  // 1/f spectrum – most natural sounding
	NoiseBrown NoiseProfile = "BROWN" // 1/f² spectrum – deep rumble, ocean-like
)

// OscillatorLayer represents a single synthesized frequency channel.
type OscillatorLayer struct {
	ID              string         `json:"id"`
	Mode            OscillatorMode `json:"mode"`
	CarrierFreqHz   float64        `json:"carrier_freq_hz"`   // Base tone audible to listener
	BeatFreqHz      float64        `json:"beat_freq_hz"`      // Entrainment delta
	LeftChannelHz   float64        `json:"left_channel_hz"`   // Binaural: left ear frequency
	RightChannelHz  float64        `json:"right_channel_hz"`  // Binaural: right ear frequency
	AmplitudeLinear float64        `json:"amplitude_linear"`  // 0.0 – 1.0 normalized
	PhaseOffsetRad  float64        `json:"phase_offset_rad"`  // Stereo imaging phase
	WaveformType    string         `json:"waveform_type"`     // "sine" | "square" | "sawtooth"
}

// NoiseLayer defines the noise channel configuration.
type NoiseLayer struct {
	Profile         NoiseProfile `json:"profile"`
	AmplitudeLinear float64      `json:"amplitude_linear"`
	CutoffLowHz     float64      `json:"cutoff_low_hz"`  // HPF cutoff
	CutoffHighHz    float64      `json:"cutoff_high_hz"` // LPF cutoff
}

// NeuralBlueprint is the core domain entity: the mathematical audio specification
// computed by the DSP engine. It is stateless, deterministic, and serializable.
type NeuralBlueprint struct {
	ID             uuid.UUID      `json:"id"`
	SessionMode    string         `json:"session_mode"`    // "FOCUS" | "SLEEP" | "CREATIVE" | "CUSTOM"
	BrainwaveTarget BrainwaveState `json:"brainwave_target"`
	SampleRateHz   int            `json:"sample_rate_hz"`  // Always 44100 for CD quality
	BitDepth       int            `json:"bit_depth"`       // 16 or 32
	DurationSec    float64        `json:"duration_sec"`    // 0 = infinite / looping
	FadeInSec      float64        `json:"fade_in_sec"`
	FadeOutSec     float64        `json:"fade_out_sec"`
	Oscillators    []OscillatorLayer `json:"oscillators"`
	Noise          NoiseLayer     `json:"noise"`
	MasterGainDB   float64        `json:"master_gain_db"`  // -60 to 0 dB
	ComputedAt     time.Time      `json:"computed_at"`
	Checksum       string         `json:"checksum"`        // SHA-256 of deterministic params
}
