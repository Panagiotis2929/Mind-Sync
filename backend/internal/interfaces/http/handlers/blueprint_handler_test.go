package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/mind-sync/neural-audio-architect/internal/application/usecases"
	"github.com/mind-sync/neural-audio-architect/internal/infrastructure/logger"
	"github.com/mind-sync/neural-audio-architect/internal/interfaces/http/handlers"
	"github.com/mind-sync/neural-audio-architect/pkg/dsp"
)

func newBlueprintHandler(t *testing.T) *handlers.BlueprintHandler {
	t.Helper()
	log, _ := logger.New(false)
	engine := dsp.NewEngine()
	uc     := usecases.NewComputeBlueprintUseCase(engine)
	return handlers.NewBlueprintHandler(uc, log)
}

func TestBlueprintHandler_Compute_ValidRequest_Returns200(t *testing.T) {
	h   := newBlueprintHandler(t)
	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/v1/blueprint/compute", h.Compute)

	body := map[string]interface{}{
		"session_mode":    "FOCUS",
		"focus_depth":     0.8,
		"calm_level":      0.3,
		"energy_level":    0.7,
		"noise_profile":   "PINK",
		"noise_volume":    0.25,
		"oscillator_mode": "BINAURAL",
		"master_volume":   0.70,
		"duration_sec":    0.0,
	}

	raw, _ := json.Marshal(body)
	req  := httptest.NewRequest(http.MethodPost, "/api/v1/blueprint/compute", bytes.NewReader(raw))
	req.Header.Set("Content-Type", "application/json")
	rec  := httptest.NewRecorder()

	h.Compute(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("response is not valid JSON: %v", err)
	}
	if resp["success"] != true {
		t.Errorf("expected success=true, got %v", resp["success"])
	}
	data, ok := resp["data"].(map[string]interface{})
	if !ok {
		t.Fatal("data field missing or wrong type")
	}
	if data["id"] == "" || data["id"] == nil {
		t.Error("blueprint ID should not be empty")
	}
	if data["brainwave_target"] == nil {
		t.Error("brainwave_target should be set")
	}
}

func TestBlueprintHandler_Compute_InvalidMode_Returns400(t *testing.T) {
	h := newBlueprintHandler(t)

	body := map[string]interface{}{
		"session_mode":    "INVALID_MODE",
		"focus_depth":     0.5,
		"calm_level":      0.5,
		"energy_level":    0.5,
		"noise_profile":   "NONE",
		"noise_volume":    0.0,
		"oscillator_mode": "BINAURAL",
		"master_volume":   0.7,
	}

	raw, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewReader(raw))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Compute(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid mode, got %d", rec.Code)
	}
}

func TestBlueprintHandler_Compute_OutOfRangeParam_Returns400(t *testing.T) {
	h := newBlueprintHandler(t)

	body := map[string]interface{}{
		"session_mode":    "FOCUS",
		"focus_depth":     1.5, // OUT OF RANGE
		"calm_level":      0.5,
		"energy_level":    0.5,
		"noise_profile":   "NONE",
		"noise_volume":    0.0,
		"oscillator_mode": "BINAURAL",
		"master_volume":   0.7,
	}

	raw, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewReader(raw))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Compute(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for out-of-range param, got %d", rec.Code)
	}
}

func TestBlueprintHandler_Compute_MalformedJSON_Returns400(t *testing.T) {
	h := newBlueprintHandler(t)

	req := httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString("{bad json"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	h.Compute(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for malformed JSON, got %d", rec.Code)
	}
}

func TestBlueprintHandler_Presets_Returns200WithList(t *testing.T) {
	h := newBlueprintHandler(t)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/blueprint/presets", nil)
	rec := httptest.NewRecorder()

	h.Presets(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}

	var resp map[string]interface{}
	json.Unmarshal(rec.Body.Bytes(), &resp) //nolint:errcheck
	data, ok := resp["data"].([]interface{})
	if !ok || len(data) == 0 {
		t.Error("expected non-empty preset list")
	}
}

func TestBlueprintHandler_Compute_AllSessionModes_Succeed(t *testing.T) {
	h     := newBlueprintHandler(t)
	modes := []string{"FOCUS", "SLEEP", "CREATIVE", "CUSTOM"}

	for _, mode := range modes {
		t.Run(mode, func(t *testing.T) {
			body := map[string]interface{}{
				"session_mode":    mode,
				"focus_depth":     0.5,
				"calm_level":      0.5,
				"energy_level":    0.5,
				"noise_profile":   "NONE",
				"noise_volume":    0.0,
				"oscillator_mode": "BINAURAL",
				"master_volume":   0.7,
				"duration_sec":    0.0,
			}
			raw, _ := json.Marshal(body)
			req := httptest.NewRequest(http.MethodPost, "/", bytes.NewReader(raw))
			req.Header.Set("Content-Type", "application/json")
			rec := httptest.NewRecorder()

			h.Compute(rec, req)

			if rec.Code != http.StatusOK {
				t.Errorf("mode %s: expected 200, got %d: %s", mode, rec.Code, rec.Body.String())
			}
		})
	}
}

func TestBlueprintHandler_Compute_AllOscillatorModes_Succeed(t *testing.T) {
	h     := newBlueprintHandler(t)
	modes := []string{"BINAURAL", "ISOCHRONIC", "SOLFEGGIO"}

	for _, mode := range modes {
		t.Run(mode, func(t *testing.T) {
			body := map[string]interface{}{
				"session_mode":    "FOCUS",
				"focus_depth":     0.5,
				"calm_level":      0.5,
				"energy_level":    0.5,
				"noise_profile":   "NONE",
				"noise_volume":    0.0,
				"oscillator_mode": mode,
				"master_volume":   0.7,
				"duration_sec":    0.0,
			}
			raw, _ := json.Marshal(body)
			req := httptest.NewRequest(http.MethodPost, "/", bytes.NewReader(raw))
			req.Header.Set("Content-Type", "application/json")
			rec := httptest.NewRecorder()
			h.Compute(rec, req)

			if rec.Code != http.StatusOK {
				t.Errorf("osc mode %s: expected 200, got %d", mode, rec.Code)
			}
		})
	}
}
