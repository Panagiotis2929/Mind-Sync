package dsp_test

import (
	"math"
	"testing"

	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
	"github.com/mind-sync/neural-audio-architect/pkg/dsp"
)

func newEngine() *dsp.Engine {
	return dsp.NewEngine()
}

func TestEngine_Compute_Focus_BiasesGammaOrBeta(t *testing.T) {
	engine := newEngine()

	bp, err := engine.Compute(dsp.SynthesisParams{
		SessionMode:  "FOCUS",
		FocusDepth:   0.90,
		CalmLevel:    0.10,
		EnergyLevel:  0.80,
		NoiseProfile: entities.NoiseNone,
		NoiseVolume:  0.0,
		OscMode:      entities.OscillatorBinaural,
		MasterVolume: 0.70,
	})

	if err != nil {
		t.Fatalf("Compute returned unexpected error: %v", err)
	}
	if bp == nil {
		t.Fatal("blueprint is nil")
	}

	// High focus depth should target Gamma or Beta
	if bp.BrainwaveTarget != entities.BrainwaveGamma && bp.BrainwaveTarget != entities.BrainwaveBeta {
		t.Errorf("expected GAMMA or BETA, got %s", bp.BrainwaveTarget)
	}
}

func TestEngine_Compute_Sleep_BiasesDeltaOrTheta(t *testing.T) {
	engine := newEngine()

	bp, err := engine.Compute(dsp.SynthesisParams{
		SessionMode:  "SLEEP",
		FocusDepth:   0.05,
		CalmLevel:    0.95,
		EnergyLevel:  0.05,
		NoiseProfile: entities.NoiseBrown,
		NoiseVolume:  0.40,
		OscMode:      entities.OscillatorBinaural,
		MasterVolume: 0.55,
	})

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if bp.BrainwaveTarget != entities.BrainwaveDelta && bp.BrainwaveTarget != entities.BrainwaveTheta {
		t.Errorf("expected DELTA or THETA for sleep, got %s", bp.BrainwaveTarget)
	}
}

func TestEngine_Compute_BinauralBeat_LeftRightDiff_EqualsBeatFreq(t *testing.T) {
	engine := newEngine()

	bp, err := engine.Compute(dsp.SynthesisParams{
		SessionMode:  "FOCUS",
		FocusDepth:   0.5,
		CalmLevel:    0.4,
		EnergyLevel:  0.5,
		NoiseProfile: entities.NoiseNone,
		NoiseVolume:  0.0,
		OscMode:      entities.OscillatorBinaural,
		MasterVolume: 0.70,
	})

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(bp.Oscillators) == 0 {
		t.Fatal("no oscillators in blueprint")
	}

	osc  := bp.Oscillators[0]
	diff := math.Abs(osc.RightChannelHz - osc.LeftChannelHz)

	// The frequency difference between ears MUST equal the beat frequency
	if math.Abs(diff-osc.BeatFreqHz) > 0.001 {
		t.Errorf(
			"|right(%.4f) - left(%.4f)| = %.4f, want beat %.4f",
			osc.RightChannelHz, osc.LeftChannelHz, diff, osc.BeatFreqHz,
		)
	}
}

func TestEngine_Compute_AmplitudeInUnitRange(t *testing.T) {
	engine := newEngine()

	bp, err := engine.Compute(dsp.SynthesisParams{
		SessionMode:  "CREATIVE",
		FocusDepth:   0.5,
		CalmLevel:    0.5,
		EnergyLevel:  0.7,
		NoiseProfile: entities.NoisePink,
		NoiseVolume:  0.3,
		OscMode:      entities.OscillatorSolfeggio,
		MasterVolume: 1.0,
	})

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	for i, osc := range bp.Oscillators {
		if osc.AmplitudeLinear < 0 || osc.AmplitudeLinear > 1.001 {
			t.Errorf("oscillator[%d] amplitude %.4f out of [0,1]", i, osc.AmplitudeLinear)
		}
	}
}

func TestEngine_Compute_Deterministic_SameParamsSameChecksum(t *testing.T) {
	engine := newEngine()
	params := dsp.SynthesisParams{
		SessionMode:  "CUSTOM",
		FocusDepth:   0.42,
		CalmLevel:    0.31,
		EnergyLevel:  0.58,
		NoiseProfile: entities.NoiseWhite,
		NoiseVolume:  0.20,
		OscMode:      entities.OscillatorIsochronic,
		MasterVolume: 0.65,
	}

	bp1, _ := engine.Compute(params)
	bp2, _ := engine.Compute(params)

	if bp1.Checksum != bp2.Checksum {
		t.Errorf("non-deterministic: checksum1=%s, checksum2=%s", bp1.Checksum, bp2.Checksum)
	}
}

func TestEngine_Compute_SampleRateIs44100(t *testing.T) {
	engine := newEngine()
	bp, err := engine.Compute(dsp.SynthesisParams{
		SessionMode:  "FOCUS",
		FocusDepth:   0.5,
		CalmLevel:    0.5,
		EnergyLevel:  0.5,
		NoiseProfile: entities.NoiseNone,
		OscMode:      entities.OscillatorBinaural,
		MasterVolume: 0.7,
	})

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if bp.SampleRateHz != 44100 {
		t.Errorf("expected 44100 Hz, got %d", bp.SampleRateHz)
	}
}

func TestEngine_Compute_MasterGainDB_NegativeForSubUnityVolume(t *testing.T) {
	engine := newEngine()
	bp, _ := engine.Compute(dsp.SynthesisParams{
		SessionMode:  "FOCUS",
		FocusDepth:   0.5,
		CalmLevel:    0.5,
		EnergyLevel:  0.5,
		NoiseProfile: entities.NoiseNone,
		OscMode:      entities.OscillatorBinaural,
		MasterVolume: 0.5, // sub-unity → negative dBFS
	})

	if bp.MasterGainDB >= 0 {
		t.Errorf("expected negative dBFS for 0.5 linear, got %.2f dB", bp.MasterGainDB)
	}
}

func TestEngine_Compute_NoiseLayerSpectralBounds(t *testing.T) {
	engine := newEngine()
	bp, _ := engine.Compute(dsp.SynthesisParams{
		SessionMode:  "SLEEP",
		FocusDepth:   0.1,
		CalmLevel:    0.9,
		EnergyLevel:  0.1,
		NoiseProfile: entities.NoiseBrown,
		NoiseVolume:  0.4,
		OscMode:      entities.OscillatorBinaural,
		MasterVolume: 0.6,
	})

	if bp.Noise.Profile != entities.NoiseBrown {
		t.Errorf("expected BROWN noise, got %s", bp.Noise.Profile)
	}
	if bp.Noise.CutoffLowHz <= 0 {
		t.Error("cutoff low must be positive")
	}
	if bp.Noise.CutoffHighHz <= bp.Noise.CutoffLowHz {
		t.Errorf("cutoff high (%.1f) must exceed cutoff low (%.1f)",
			bp.Noise.CutoffHighHz, bp.Noise.CutoffLowHz)
	}
}

func TestEngine_Compute_IsochronicMode_BothChannelsSameFreq(t *testing.T) {
	engine := newEngine()
	bp, _ := engine.Compute(dsp.SynthesisParams{
		SessionMode:  "FOCUS",
		FocusDepth:   0.5,
		CalmLevel:    0.4,
		EnergyLevel:  0.6,
		NoiseProfile: entities.NoiseNone,
		OscMode:      entities.OscillatorIsochronic,
		MasterVolume: 0.7,
	})

	for i, osc := range bp.Oscillators {
		if osc.Mode == entities.OscillatorIsochronic {
			if math.Abs(osc.LeftChannelHz-osc.RightChannelHz) > 0.001 {
				t.Errorf("isochronic oscillator[%d] left(%.2f) != right(%.2f)",
					i, osc.LeftChannelHz, osc.RightChannelHz)
			}
		}
	}
}

func TestEngine_Compute_CreativeMode_TargetsAlpha(t *testing.T) {
	engine := newEngine()
	bp, _ := engine.Compute(dsp.SynthesisParams{
		SessionMode:  "CREATIVE",
		FocusDepth:   0.5,
		CalmLevel:    0.5,
		EnergyLevel:  0.5,
		NoiseProfile: entities.NoiseNone,
		OscMode:      entities.OscillatorBinaural,
		MasterVolume: 0.7,
	})

	if bp.BrainwaveTarget != entities.BrainwaveAlpha {
		t.Errorf("CREATIVE mode should target ALPHA, got %s", bp.BrainwaveTarget)
	}
}
