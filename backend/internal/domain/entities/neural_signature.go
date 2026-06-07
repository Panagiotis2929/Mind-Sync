package entities

import (
	"time"

	"github.com/google/uuid"
)

// NeuralSignature is a user-saved preset: a named collection of synthesis parameters
// that reproducibly generates a specific NeuralBlueprint.
type NeuralSignature struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	Description  string    `json:"description"`
	SessionMode  string    `json:"session_mode"`
	FocusDepth   float64   `json:"focus_depth"`    // 0.0 – 1.0
	CalmLevel    float64   `json:"calm_level"`     // 0.0 – 1.0
	EnergyLevel  float64   `json:"energy_level"`   // 0.0 – 1.0
	NoiseProfile NoiseProfile `json:"noise_profile"`
	NoiseVolume  float64   `json:"noise_volume"`   // 0.0 – 1.0
	OscMode      OscillatorMode `json:"oscillator_mode"`
	MasterVolume float64   `json:"master_volume"`  // 0.0 – 1.0
	Tags         []string  `json:"tags"`
	IsFavorite   bool      `json:"is_favorite"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// Validate enforces domain invariants on NeuralSignature.
func (ns *NeuralSignature) Validate() error {
	if ns.Name == "" {
		return ErrInvalidSignatureName
	}
	if ns.FocusDepth < 0 || ns.FocusDepth > 1 {
		return ErrParameterOutOfRange("focus_depth", ns.FocusDepth)
	}
	if ns.CalmLevel < 0 || ns.CalmLevel > 1 {
		return ErrParameterOutOfRange("calm_level", ns.CalmLevel)
	}
	if ns.EnergyLevel < 0 || ns.EnergyLevel > 1 {
		return ErrParameterOutOfRange("energy_level", ns.EnergyLevel)
	}
	if ns.NoiseVolume < 0 || ns.NoiseVolume > 1 {
		return ErrParameterOutOfRange("noise_volume", ns.NoiseVolume)
	}
	if ns.MasterVolume < 0 || ns.MasterVolume > 1 {
		return ErrParameterOutOfRange("master_volume", ns.MasterVolume)
	}
	return nil
}

// SessionRecord captures metadata about a completed or active listening session.
type SessionRecord struct {
	ID              uuid.UUID  `json:"id"`
	SignatureID     *uuid.UUID `json:"signature_id,omitempty"` // nil if ad-hoc
	BlueprintID     uuid.UUID  `json:"blueprint_id"`
	SessionMode     string     `json:"session_mode"`
	BrainwaveTarget BrainwaveState `json:"brainwave_target"`
	StartedAt       time.Time  `json:"started_at"`
	EndedAt         *time.Time `json:"ended_at,omitempty"`
	DurationSec     float64    `json:"duration_sec"`
	Notes           string     `json:"notes"`
}
