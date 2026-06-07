package usecases

import (
	"context"
	"fmt"
	"strings"

	"github.com/mind-sync/neural-audio-architect/internal/application/dtos"
	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
	"github.com/mind-sync/neural-audio-architect/pkg/dsp"
)

// ComputeBlueprintUseCase orchestrates the DSP computation pipeline.
// It validates input DTOs, maps to domain params, delegates to the DSP engine,
// and returns a transport-safe DTO.
type ComputeBlueprintUseCase struct {
	engine *dsp.Engine
}

// NewComputeBlueprintUseCase injects the DSP engine dependency.
func NewComputeBlueprintUseCase(engine *dsp.Engine) *ComputeBlueprintUseCase {
	return &ComputeBlueprintUseCase{engine: engine}
}

// Execute validates, computes, and maps a blueprint computation request.
func (uc *ComputeBlueprintUseCase) Execute(
	ctx context.Context,
	req *dtos.ComputeBlueprintRequest,
) (*dtos.NeuralBlueprintDTO, error) {
	if err := validateComputeRequest(req); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	params := dsp.SynthesisParams{
		SessionMode:  req.SessionMode,
		FocusDepth:   req.FocusDepth,
		CalmLevel:    req.CalmLevel,
		EnergyLevel:  req.EnergyLevel,
		NoiseProfile: entities.NoiseProfile(req.NoiseProfile),
		NoiseVolume:  req.NoiseVolume,
		OscMode:      entities.OscillatorMode(req.OscillatorMode),
		MasterVolume: req.MasterVolume,
		DurationSec:  req.DurationSec,
	}

	blueprint, err := uc.engine.Compute(params)
	if err != nil {
		return nil, fmt.Errorf("DSP computation error: %w", err)
	}

	return mapBlueprintToDTO(blueprint), nil
}

// validateComputeRequest enforces request-level constraints.
func validateComputeRequest(req *dtos.ComputeBlueprintRequest) error {
	validModes := map[string]bool{"FOCUS": true, "SLEEP": true, "CREATIVE": true, "CUSTOM": true}
	if !validModes[strings.ToUpper(req.SessionMode)] {
		return fmt.Errorf("invalid session_mode '%s'; must be FOCUS|SLEEP|CREATIVE|CUSTOM", req.SessionMode)
	}
	req.SessionMode = strings.ToUpper(req.SessionMode)

	validNoise := map[string]bool{"NONE": true, "WHITE": true, "PINK": true, "BROWN": true}
	if !validNoise[strings.ToUpper(req.NoiseProfile)] {
		return fmt.Errorf("invalid noise_profile '%s'; must be NONE|WHITE|PINK|BROWN", req.NoiseProfile)
	}
	req.NoiseProfile = strings.ToUpper(req.NoiseProfile)

	validOsc := map[string]bool{"BINAURAL": true, "ISOCHRONIC": true, "SOLFEGGIO": true}
	if !validOsc[strings.ToUpper(req.OscillatorMode)] {
		return fmt.Errorf("invalid oscillator_mode '%s'; must be BINAURAL|ISOCHRONIC|SOLFEGGIO", req.OscillatorMode)
	}
	req.OscillatorMode = strings.ToUpper(req.OscillatorMode)

	type paramCheck struct {
		name string
		val  float64
	}
	params := []paramCheck{
		{"focus_depth", req.FocusDepth},
		{"calm_level", req.CalmLevel},
		{"energy_level", req.EnergyLevel},
		{"noise_volume", req.NoiseVolume},
		{"master_volume", req.MasterVolume},
	}
	for _, p := range params {
		if p.val < 0 || p.val > 1 {
			return fmt.Errorf("parameter '%s' = %.4f is out of range [0.0, 1.0]", p.name, p.val)
		}
	}

	if req.DurationSec < 0 {
		return fmt.Errorf("duration_sec must be >= 0 (0 = loop)")
	}

	return nil
}

// mapBlueprintToDTO converts the domain entity to a transport DTO.
// This is the anti-corruption layer that decouples domain from HTTP.
func mapBlueprintToDTO(b *entities.NeuralBlueprint) *dtos.NeuralBlueprintDTO {
	oscDTOs := make([]dtos.OscillatorLayerDTO, len(b.Oscillators))
	for i, osc := range b.Oscillators {
		oscDTOs[i] = dtos.OscillatorLayerDTO{
			ID:              osc.ID,
			Mode:            string(osc.Mode),
			CarrierFreqHz:   osc.CarrierFreqHz,
			BeatFreqHz:      osc.BeatFreqHz,
			LeftChannelHz:   osc.LeftChannelHz,
			RightChannelHz:  osc.RightChannelHz,
			AmplitudeLinear: osc.AmplitudeLinear,
			PhaseOffsetRad:  osc.PhaseOffsetRad,
			WaveformType:    osc.WaveformType,
		}
	}

	return &dtos.NeuralBlueprintDTO{
		ID:              b.ID.String(),
		SessionMode:     b.SessionMode,
		BrainwaveTarget: string(b.BrainwaveTarget),
		SampleRateHz:    b.SampleRateHz,
		BitDepth:        b.BitDepth,
		DurationSec:     b.DurationSec,
		FadeInSec:       b.FadeInSec,
		FadeOutSec:      b.FadeOutSec,
		Oscillators:     oscDTOs,
		Noise: dtos.NoiseLayerDTO{
			Profile:         string(b.Noise.Profile),
			AmplitudeLinear: b.Noise.AmplitudeLinear,
			CutoffLowHz:     b.Noise.CutoffLowHz,
			CutoffHighHz:    b.Noise.CutoffHighHz,
		},
		MasterGainDB: b.MasterGainDB,
		ComputedAt:   b.ComputedAt.Format("2006-01-02T15:04:05Z"),
		Checksum:     b.Checksum,
	}
}
