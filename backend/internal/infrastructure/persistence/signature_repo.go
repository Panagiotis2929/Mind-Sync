package persistence

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
	"github.com/mind-sync/neural-audio-architect/internal/domain/repositories"
)

// Compile-time interface assertion
var _ repositories.NeuralSignatureRepository = (*SQLiteSignatureRepository)(nil)

// SQLiteSignatureRepository is the SQLite-backed implementation of NeuralSignatureRepository.
type SQLiteSignatureRepository struct {
	db *sql.DB
}

// NewSQLiteSignatureRepository creates a new repository backed by the given db handle.
func NewSQLiteSignatureRepository(db *sql.DB) *SQLiteSignatureRepository {
	return &SQLiteSignatureRepository{db: db}
}

// Save upserts a NeuralSignature (INSERT OR REPLACE semantics).
func (r *SQLiteSignatureRepository) Save(ctx context.Context, sig *entities.NeuralSignature) error {
	tagsJSON, err := json.Marshal(sig.Tags)
	if err != nil {
		return fmt.Errorf("failed to marshal tags: %w", err)
	}

	const q = `
		INSERT INTO neural_signatures
			(id, name, description, session_mode, focus_depth, calm_level, energy_level,
			 noise_profile, noise_volume, oscillator_mode, master_volume, tags, is_favorite,
			 created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			name            = excluded.name,
			description     = excluded.description,
			session_mode    = excluded.session_mode,
			focus_depth     = excluded.focus_depth,
			calm_level      = excluded.calm_level,
			energy_level    = excluded.energy_level,
			noise_profile   = excluded.noise_profile,
			noise_volume    = excluded.noise_volume,
			oscillator_mode = excluded.oscillator_mode,
			master_volume   = excluded.master_volume,
			tags            = excluded.tags,
			is_favorite     = excluded.is_favorite,
			updated_at      = excluded.updated_at`

	_, err = r.db.ExecContext(ctx, q,
		sig.ID.String(), sig.Name, sig.Description, sig.SessionMode,
		sig.FocusDepth, sig.CalmLevel, sig.EnergyLevel,
		string(sig.NoiseProfile), sig.NoiseVolume, string(sig.OscMode),
		sig.MasterVolume, string(tagsJSON), boolToInt(sig.IsFavorite),
		sig.CreatedAt.Format(time.RFC3339), sig.UpdatedAt.Format(time.RFC3339),
	)
	if err != nil {
		return fmt.Errorf("failed to upsert signature: %w", err)
	}
	return nil
}

// FindByID retrieves a single signature by UUID.
func (r *SQLiteSignatureRepository) FindByID(ctx context.Context, id uuid.UUID) (*entities.NeuralSignature, error) {
	const q = `SELECT id, name, description, session_mode, focus_depth, calm_level, energy_level,
		noise_profile, noise_volume, oscillator_mode, master_volume, tags, is_favorite,
		created_at, updated_at FROM neural_signatures WHERE id = ?`

	row := r.db.QueryRowContext(ctx, q, id.String())
	sig, err := scanSignature(row)
	if err == sql.ErrNoRows {
		return nil, entities.ErrSignatureNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("failed to scan signature: %w", err)
	}
	return sig, nil
}

// FindAll retrieves all signatures, ordered by most recently updated.
func (r *SQLiteSignatureRepository) FindAll(ctx context.Context) ([]*entities.NeuralSignature, error) {
	const q = `SELECT id, name, description, session_mode, focus_depth, calm_level, energy_level,
		noise_profile, noise_volume, oscillator_mode, master_volume, tags, is_favorite,
		created_at, updated_at FROM neural_signatures ORDER BY updated_at DESC`

	return r.querySignatures(ctx, q)
}

// FindFavorites retrieves only favorited signatures.
func (r *SQLiteSignatureRepository) FindFavorites(ctx context.Context) ([]*entities.NeuralSignature, error) {
	const q = `SELECT id, name, description, session_mode, focus_depth, calm_level, energy_level,
		noise_profile, noise_volume, oscillator_mode, master_volume, tags, is_favorite,
		created_at, updated_at FROM neural_signatures WHERE is_favorite = 1 ORDER BY updated_at DESC`

	return r.querySignatures(ctx, q)
}

// Delete removes a signature permanently.
func (r *SQLiteSignatureRepository) Delete(ctx context.Context, id uuid.UUID) error {
	res, err := r.db.ExecContext(ctx, `DELETE FROM neural_signatures WHERE id = ?`, id.String())
	if err != nil {
		return fmt.Errorf("failed to delete signature: %w", err)
	}
	affected, _ := res.RowsAffected()
	if affected == 0 {
		return entities.ErrSignatureNotFound
	}
	return nil
}

// ToggleFavorite flips the is_favorite flag for a signature.
func (r *SQLiteSignatureRepository) ToggleFavorite(ctx context.Context, id uuid.UUID) error {
	const q = `UPDATE neural_signatures SET is_favorite = 1 - is_favorite, updated_at = ?
		WHERE id = ?`
	res, err := r.db.ExecContext(ctx, q, time.Now().UTC().Format(time.RFC3339), id.String())
	if err != nil {
		return fmt.Errorf("failed to toggle favorite: %w", err)
	}
	affected, _ := res.RowsAffected()
	if affected == 0 {
		return entities.ErrSignatureNotFound
	}
	return nil
}

// --- Private helpers ---

func (r *SQLiteSignatureRepository) querySignatures(ctx context.Context, q string, args ...interface{}) ([]*entities.NeuralSignature, error) {
	rows, err := r.db.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("query error: %w", err)
	}
	defer rows.Close()

	var results []*entities.NeuralSignature
	for rows.Next() {
		sig, err := scanSignature(rows)
		if err != nil {
			return nil, fmt.Errorf("scan error: %w", err)
		}
		results = append(results, sig)
	}
	return results, rows.Err()
}

// scanner is satisfied by both *sql.Row and *sql.Rows.
type scanner interface {
	Scan(dest ...interface{}) error
}

func scanSignature(s scanner) (*entities.NeuralSignature, error) {
	var (
		sig      entities.NeuralSignature
		idStr    string
		tagsJSON string
		createdS string
		updatedS string
		isFav    int
		oscMode  string
		noiseP   string
	)

	err := s.Scan(
		&idStr, &sig.Name, &sig.Description, &sig.SessionMode,
		&sig.FocusDepth, &sig.CalmLevel, &sig.EnergyLevel,
		&noiseP, &sig.NoiseVolume, &oscMode,
		&sig.MasterVolume, &tagsJSON, &isFav, &createdS, &updatedS,
	)
	if err != nil {
		return nil, err
	}

	sig.ID, _ = uuid.Parse(idStr)
	sig.NoiseProfile = entities.NoiseProfile(noiseP)
	sig.OscMode = entities.OscillatorMode(oscMode)
	sig.IsFavorite = isFav == 1

	if err := json.Unmarshal([]byte(tagsJSON), &sig.Tags); err != nil {
		sig.Tags = []string{}
	}
	sig.CreatedAt, _ = time.Parse(time.RFC3339, createdS)
	sig.UpdatedAt, _ = time.Parse(time.RFC3339, updatedS)

	return &sig, nil
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}
