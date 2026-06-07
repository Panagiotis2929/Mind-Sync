package dtos

// ComputeBlueprintRequest is the validated inbound DTO for DSP computation requests.
// All float fields must be in [0.0, 1.0]; session_mode is an enum.
type ComputeBlueprintRequest struct {
	SessionMode     string  `json:"session_mode"`      // Required: "FOCUS"|"SLEEP"|"CREATIVE"|"CUSTOM"
	FocusDepth      float64 `json:"focus_depth"`       // 0.0–1.0
	CalmLevel       float64 `json:"calm_level"`        // 0.0–1.0
	EnergyLevel     float64 `json:"energy_level"`      // 0.0–1.0
	NoiseProfile    string  `json:"noise_profile"`     // "NONE"|"WHITE"|"PINK"|"BROWN"
	NoiseVolume     float64 `json:"noise_volume"`      // 0.0–1.0
	OscillatorMode  string  `json:"oscillator_mode"`   // "BINAURAL"|"ISOCHRONIC"|"SOLFEGGIO"
	MasterVolume    float64 `json:"master_volume"`     // 0.0–1.0
	DurationSec     float64 `json:"duration_sec"`      // 0 = loop
}

// OscillatorLayerDTO mirrors the domain entity for API transport.
type OscillatorLayerDTO struct {
	ID              string  `json:"id"`
	Mode            string  `json:"mode"`
	CarrierFreqHz   float64 `json:"carrier_freq_hz"`
	BeatFreqHz      float64 `json:"beat_freq_hz"`
	LeftChannelHz   float64 `json:"left_channel_hz"`
	RightChannelHz  float64 `json:"right_channel_hz"`
	AmplitudeLinear float64 `json:"amplitude_linear"`
	PhaseOffsetRad  float64 `json:"phase_offset_rad"`
	WaveformType    string  `json:"waveform_type"`
}

// NoiseLayerDTO mirrors the domain entity for API transport.
type NoiseLayerDTO struct {
	Profile         string  `json:"profile"`
	AmplitudeLinear float64 `json:"amplitude_linear"`
	CutoffLowHz     float64 `json:"cutoff_low_hz"`
	CutoffHighHz    float64 `json:"cutoff_high_hz"`
}

// NeuralBlueprintDTO is the outbound DTO returned to the frontend.
type NeuralBlueprintDTO struct {
	ID              string               `json:"id"`
	SessionMode     string               `json:"session_mode"`
	BrainwaveTarget string               `json:"brainwave_target"`
	SampleRateHz    int                  `json:"sample_rate_hz"`
	BitDepth        int                  `json:"bit_depth"`
	DurationSec     float64              `json:"duration_sec"`
	FadeInSec       float64              `json:"fade_in_sec"`
	FadeOutSec      float64              `json:"fade_out_sec"`
	Oscillators     []OscillatorLayerDTO `json:"oscillators"`
	Noise           NoiseLayerDTO        `json:"noise"`
	MasterGainDB    float64              `json:"master_gain_db"`
	ComputedAt      string               `json:"computed_at"`
	Checksum        string               `json:"checksum"`
}
