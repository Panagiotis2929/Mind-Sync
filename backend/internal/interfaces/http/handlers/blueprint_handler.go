package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/mind-sync/neural-audio-architect/internal/application/dtos"
	"github.com/mind-sync/neural-audio-architect/internal/application/usecases"
	"github.com/mind-sync/neural-audio-architect/internal/infrastructure/logger"
	"go.uber.org/zap"
)

// BlueprintHandler handles all /api/v1/blueprint endpoints.
type BlueprintHandler struct {
	computeUC *usecases.ComputeBlueprintUseCase
	log       logger.Logger
}

// NewBlueprintHandler creates a handler with its required use case.
func NewBlueprintHandler(computeUC *usecases.ComputeBlueprintUseCase, log logger.Logger) *BlueprintHandler {
	return &BlueprintHandler{computeUC: computeUC, log: log}
}

// Compute handles POST /api/v1/blueprint/compute
// It accepts synthesis parameters and returns a mathematical audio blueprint.
//
//	Request:  { "session_mode": "FOCUS", "focus_depth": 0.8, ... }
//	Response: { "success": true, "data": { NeuralBlueprintDTO } }
func (h *BlueprintHandler) Compute(w http.ResponseWriter, r *http.Request) {
	var req dtos.ComputeBlueprintRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.log.Warn("malformed blueprint request", zap.Error(err))
		respondBadRequest(w, "Invalid JSON body: "+err.Error())
		return
	}
	defer r.Body.Close()

	blueprint, err := h.computeUC.Execute(r.Context(), &req)
	if err != nil {
		if strings.Contains(err.Error(), "validation failed") {
			respondBadRequest(w, err.Error())
			return
		}
		h.log.Error("blueprint computation failed", zap.Error(err))
		respondInternalError(w)
		return
	}

	h.log.Info("blueprint computed",
		zap.String("id", blueprint.ID),
		zap.String("mode", blueprint.SessionMode),
		zap.String("brainwave", blueprint.BrainwaveTarget),
		zap.Float64("beat_hz", blueprint.Oscillators[0].BeatFreqHz),
	)

	respondOK(w, blueprint)
}

// Presets handles GET /api/v1/blueprint/presets
// Returns hardcoded factory presets that users can load as starting points.
func (h *BlueprintHandler) Presets(w http.ResponseWriter, r *http.Request) {
	presets := []map[string]interface{}{
		{
			"id":              "preset_deep_focus",
			"name":            "Deep Focus",
			"description":     "High-beta binaural beats for sustained cognitive performance",
			"icon":            "brain",
			"session_mode":    "FOCUS",
			"focus_depth":     0.85,
			"calm_level":      0.30,
			"energy_level":    0.70,
			"noise_profile":   "PINK",
			"noise_volume":    0.25,
			"oscillator_mode": "BINAURAL",
			"master_volume":   0.72,
		},
		{
			"id":              "preset_sleep_induction",
			"name":            "Sleep Induction",
			"description":     "Delta-wave theta entrainment for deep, restorative sleep",
			"icon":            "moon",
			"session_mode":    "SLEEP",
			"focus_depth":     0.10,
			"calm_level":      0.95,
			"energy_level":    0.05,
			"noise_profile":   "BROWN",
			"noise_volume":    0.40,
			"oscillator_mode": "BINAURAL",
			"master_volume":   0.55,
		},
		{
			"id":              "preset_creative_flow",
			"name":            "Creative Flow",
			"description":     "Alpha-theta crossover for divergent thinking and inspiration",
			"icon":            "sparkles",
			"session_mode":    "CREATIVE",
			"focus_depth":     0.45,
			"calm_level":      0.55,
			"energy_level":    0.60,
			"noise_profile":   "PINK",
			"noise_volume":    0.20,
			"oscillator_mode": "SOLFEGGIO",
			"master_volume":   0.65,
		},
		{
			"id":              "preset_stress_release",
			"name":            "Stress Release",
			"description":     "Isochronic alpha pulses to deactivate the sympathetic nervous system",
			"icon":            "leaf",
			"session_mode":    "CREATIVE",
			"focus_depth":     0.25,
			"calm_level":      0.80,
			"energy_level":    0.30,
			"noise_profile":   "PINK",
			"noise_volume":    0.35,
			"oscillator_mode": "ISOCHRONIC",
			"master_volume":   0.60,
		},
		{
			"id":              "preset_gamma_boost",
			"name":            "Gamma Boost",
			"description":     "High-frequency gamma entrainment for peak mental clarity",
			"icon":            "zap",
			"session_mode":    "FOCUS",
			"focus_depth":     1.0,
			"calm_level":      0.20,
			"energy_level":    0.90,
			"noise_profile":   "WHITE",
			"noise_volume":    0.15,
			"oscillator_mode": "ISOCHRONIC",
			"master_volume":   0.68,
		},
	}

	respondOKWithMeta(w, presets, &APIMeta{Count: len(presets)})
}
