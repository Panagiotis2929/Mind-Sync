package persistence

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
	"github.com/mind-sync/neural-audio-architect/internal/domain/repositories"
)

// Compile-time interface assertion
var _ repositories.SessionRepository = (*SQLiteSessionRepository)(nil)

// SQLiteSessionRepository is the SQLite-backed implementation of SessionRepository.
type SQLiteSessionRepository struct {
	db *sql.DB
}

// NewSQLiteSessionRepository creates a new session repository.
func NewSQLiteSessionRepository(db *sql.DB) *SQLiteSessionRepository {
	return &SQLiteSessionRepository{db: db}
}

// CreateSession persists a new session record.
func (r *SQLiteSessionRepository) CreateSession(ctx context.Context, session *entities.SessionRecord) error {
	const q = `
		INSERT INTO session_records
			(id, signature_id, blueprint_id, session_mode, brainwave_target, started_at, duration_sec, notes)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`

	var sigID interface{}
	if session.SignatureID != nil {
		sigID = session.SignatureID.String()
	}

	_, err := r.db.ExecContext(ctx, q,
		session.ID.String(),
		sigID,
		session.BlueprintID.String(),
		session.SessionMode,
		string(session.BrainwaveTarget),
		session.StartedAt.Format(time.RFC3339),
		session.DurationSec,
		session.Notes,
	)
	if err != nil {
		return fmt.Errorf("failed to create session: %w", err)
	}
	return nil
}

// FinalizeSession updates ended_at and duration_sec for a completed session.
func (r *SQLiteSessionRepository) FinalizeSession(ctx context.Context, id uuid.UUID, durationSec float64) error {
	const q = `UPDATE session_records SET ended_at = ?, duration_sec = ? WHERE id = ?`
	res, err := r.db.ExecContext(ctx, q,
		time.Now().UTC().Format(time.RFC3339),
		durationSec,
		id.String(),
	)
	if err != nil {
		return fmt.Errorf("failed to finalize session: %w", err)
	}
	affected, _ := res.RowsAffected()
	if affected == 0 {
		return entities.ErrSessionNotFound
	}
	return nil
}

// FindByID retrieves a single session.
func (r *SQLiteSessionRepository) FindByID(ctx context.Context, id uuid.UUID) (*entities.SessionRecord, error) {
	const q = `SELECT id, signature_id, blueprint_id, session_mode, brainwave_target,
		started_at, ended_at, duration_sec, notes FROM session_records WHERE id = ?`

	row := r.db.QueryRowContext(ctx, q, id.String())
	s, err := scanSession(row)
	if err == sql.ErrNoRows {
		return nil, entities.ErrSessionNotFound
	}
	if err != nil {
		return nil, err
	}
	return s, nil
}

// FindRecent retrieves the N most recent sessions, ordered by started_at DESC.
func (r *SQLiteSessionRepository) FindRecent(ctx context.Context, limit int) ([]*entities.SessionRecord, error) {
	const q = `SELECT id, signature_id, blueprint_id, session_mode, brainwave_target,
		started_at, ended_at, duration_sec, notes
		FROM session_records ORDER BY started_at DESC LIMIT ?`

	rows, err := r.db.QueryContext(ctx, q, limit)
	if err != nil {
		return nil, fmt.Errorf("query error: %w", err)
	}
	defer rows.Close()
	return collectSessions(rows)
}

// FindBySignature retrieves all sessions for a given preset.
func (r *SQLiteSessionRepository) FindBySignature(ctx context.Context, sigID uuid.UUID) ([]*entities.SessionRecord, error) {
	const q = `SELECT id, signature_id, blueprint_id, session_mode, brainwave_target,
		started_at, ended_at, duration_sec, notes
		FROM session_records WHERE signature_id = ? ORDER BY started_at DESC`

	rows, err := r.db.QueryContext(ctx, q, sigID.String())
	if err != nil {
		return nil, fmt.Errorf("query error: %w", err)
	}
	defer rows.Close()
	return collectSessions(rows)
}

// TotalListeningSeconds sums all recorded session durations.
func (r *SQLiteSessionRepository) TotalListeningSeconds(ctx context.Context) (float64, error) {
	const q = `SELECT COALESCE(SUM(duration_sec), 0.0) FROM session_records`
	var total float64
	err := r.db.QueryRowContext(ctx, q).Scan(&total)
	if err != nil {
		return 0, fmt.Errorf("failed to aggregate duration: %w", err)
	}
	return total, nil
}

// --- Private helpers ---

func scanSession(s scanner) (*entities.SessionRecord, error) {
	var (
		rec         entities.SessionRecord
		idStr       string
		sigIDStr    sql.NullString
		blueprintID string
		startedS    string
		endedS      sql.NullString
		brainwave   string
	)

	err := s.Scan(
		&idStr, &sigIDStr, &blueprintID,
		&rec.SessionMode, &brainwave, &startedS, &endedS,
		&rec.DurationSec, &rec.Notes,
	)
	if err != nil {
		return nil, err
	}

	rec.ID, _ = uuid.Parse(idStr)
	rec.BlueprintID, _ = uuid.Parse(blueprintID)
	rec.BrainwaveTarget = entities.BrainwaveState(brainwave)
	rec.StartedAt, _ = time.Parse(time.RFC3339, startedS)

	if sigIDStr.Valid {
		sigID, _ := uuid.Parse(sigIDStr.String)
		rec.SignatureID = &sigID
	}
	if endedS.Valid {
		t, _ := time.Parse(time.RFC3339, endedS.String)
		rec.EndedAt = &t
	}

	return &rec, nil
}

func collectSessions(rows *sql.Rows) ([]*entities.SessionRecord, error) {
	var results []*entities.SessionRecord
	for rows.Next() {
		s, err := scanSession(rows)
		if err != nil {
			return nil, err
		}
		results = append(results, s)
	}
	return results, rows.Err()
}
