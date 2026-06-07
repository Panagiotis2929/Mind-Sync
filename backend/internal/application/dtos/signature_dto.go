package dtos

// CreateSignatureRequest is the inbound DTO for saving a neural preset.
type CreateSignatureRequest struct {
	Name            string   `json:"name"`
	Description     string   `json:"description"`
	SessionMode     string   `json:"session_mode"`
	FocusDepth      float64  `json:"focus_depth"`
	CalmLevel       float64  `json:"calm_level"`
	EnergyLevel     float64  `json:"energy_level"`
	NoiseProfile    string   `json:"noise_profile"`
	NoiseVolume     float64  `json:"noise_volume"`
	OscillatorMode  string   `json:"oscillator_mode"`
	MasterVolume    float64  `json:"master_volume"`
	Tags            []string `json:"tags"`
}

// UpdateSignatureRequest allows partial updates to a signature.
type UpdateSignatureRequest struct {
	Name         *string  `json:"name,omitempty"`
	Description  *string  `json:"description,omitempty"`
	Tags         []string `json:"tags,omitempty"`
	IsFavorite   *bool    `json:"is_favorite,omitempty"`
}

// NeuralSignatureDTO is the outbound representation of a saved preset.
type NeuralSignatureDTO struct {
	ID             string   `json:"id"`
	Name           string   `json:"name"`
	Description    string   `json:"description"`
	SessionMode    string   `json:"session_mode"`
	FocusDepth     float64  `json:"focus_depth"`
	CalmLevel      float64  `json:"calm_level"`
	EnergyLevel    float64  `json:"energy_level"`
	NoiseProfile   string   `json:"noise_profile"`
	NoiseVolume    float64  `json:"noise_volume"`
	OscillatorMode string   `json:"oscillator_mode"`
	MasterVolume   float64  `json:"master_volume"`
	Tags           []string `json:"tags"`
	IsFavorite     bool     `json:"is_favorite"`
	CreatedAt      string   `json:"created_at"`
	UpdatedAt      string   `json:"updated_at"`
}

// CreateSessionRequest records the start of a listening session.
type CreateSessionRequest struct {
	SignatureID string `json:"signature_id,omitempty"` // Optional UUID string
	BlueprintID string `json:"blueprint_id"`
	SessionMode string `json:"session_mode"`
}

// FinalizeSessionRequest closes a session with its actual duration.
type FinalizeSessionRequest struct {
	DurationSec float64 `json:"duration_sec"`
	Notes       string  `json:"notes,omitempty"`
}

// SessionRecordDTO is the outbound representation of a session history entry.
type SessionRecordDTO struct {
	ID              string  `json:"id"`
	SignatureID     string  `json:"signature_id,omitempty"`
	BlueprintID     string  `json:"blueprint_id"`
	SessionMode     string  `json:"session_mode"`
	BrainwaveTarget string  `json:"brainwave_target"`
	StartedAt       string  `json:"started_at"`
	EndedAt         string  `json:"ended_at,omitempty"`
	DurationSec     float64 `json:"duration_sec"`
	Notes           string  `json:"notes,omitempty"`
}

// StatsDTO aggregates user analytics for the dashboard.
type StatsDTO struct {
	TotalSessions        int     `json:"total_sessions"`
	TotalListeningSec    float64 `json:"total_listening_sec"`
	FavoriteMode         string  `json:"favorite_mode"`
	SavedSignatures      int     `json:"saved_signatures"`
}
