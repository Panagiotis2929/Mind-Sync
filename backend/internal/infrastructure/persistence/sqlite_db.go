package persistence

import (
	"context"
	"database/sql"
	"fmt"

	_ "github.com/mattn/go-sqlite3"
)

const schema = `
PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;
PRAGMA synchronous=NORMAL;

CREATE TABLE IF NOT EXISTS neural_signatures (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT NOT NULL DEFAULT '',
    session_mode    TEXT NOT NULL,
    focus_depth     REAL NOT NULL DEFAULT 0.5,
    calm_level      REAL NOT NULL DEFAULT 0.5,
    energy_level    REAL NOT NULL DEFAULT 0.5,
    noise_profile   TEXT NOT NULL DEFAULT 'NONE',
    noise_volume    REAL NOT NULL DEFAULT 0.0,
    oscillator_mode TEXT NOT NULL DEFAULT 'BINAURAL',
    master_volume   REAL NOT NULL DEFAULT 0.7,
    tags            TEXT NOT NULL DEFAULT '[]',
    is_favorite     INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS session_records (
    id               TEXT PRIMARY KEY,
    signature_id     TEXT REFERENCES neural_signatures(id) ON DELETE SET NULL,
    blueprint_id     TEXT NOT NULL,
    session_mode     TEXT NOT NULL,
    brainwave_target TEXT NOT NULL DEFAULT '',
    started_at       TEXT NOT NULL,
    ended_at         TEXT,
    duration_sec     REAL NOT NULL DEFAULT 0.0,
    notes            TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_signatures_updated   ON neural_signatures(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_signatures_favorite  ON neural_signatures(is_favorite);
CREATE INDEX IF NOT EXISTS idx_sessions_started     ON session_records(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_signature   ON session_records(signature_id);
`

// NewSQLiteDB opens (or creates) the SQLite database and runs schema migrations.
// It returns a ready-to-use *sql.DB with WAL mode and foreign keys enabled.
func NewSQLiteDB(dataSourceName string) (*sql.DB, error) {
	db, err := sql.Open("sqlite3", dataSourceName)
	if err != nil {
		return nil, fmt.Errorf("failed to open SQLite at '%s': %w", dataSourceName, err)
	}

	// Connection pool settings appropriate for SQLite's single-writer model
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)

	ctx := context.Background()
	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping SQLite: %w", err)
	}

	if _, err := db.ExecContext(ctx, schema); err != nil {
		return nil, fmt.Errorf("failed to apply schema: %w", err)
	}

	return db, nil
}
