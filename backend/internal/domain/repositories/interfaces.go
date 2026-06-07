package repositories

import (
	"context"

	"github.com/google/uuid"
	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
)

// NeuralSignatureRepository defines the persistence contract for user presets.
// Implementations must be thread-safe and context-aware.
type NeuralSignatureRepository interface {
	// Save persists a new or updated NeuralSignature. Upsert semantics.
	Save(ctx context.Context, sig *entities.NeuralSignature) error

	// FindByID retrieves a single signature by its UUID.
	FindByID(ctx context.Context, id uuid.UUID) (*entities.NeuralSignature, error)

	// FindAll retrieves all signatures ordered by UpdatedAt DESC.
	FindAll(ctx context.Context) ([]*entities.NeuralSignature, error)

	// FindFavorites retrieves only favorited signatures.
	FindFavorites(ctx context.Context) ([]*entities.NeuralSignature, error)

	// Delete permanently removes a signature.
	Delete(ctx context.Context, id uuid.UUID) error

	// ToggleFavorite flips the IsFavorite flag atomically.
	ToggleFavorite(ctx context.Context, id uuid.UUID) error
}

// SessionRepository defines the persistence contract for session history.
type SessionRepository interface {
	// CreateSession persists a new session record (start of a listening session).
	CreateSession(ctx context.Context, session *entities.SessionRecord) error

	// FinalizeSession marks a session as ended and writes duration.
	FinalizeSession(ctx context.Context, id uuid.UUID, durationSec float64) error

	// FindByID retrieves a session by its UUID.
	FindByID(ctx context.Context, id uuid.UUID) (*entities.SessionRecord, error)

	// FindRecent retrieves the N most recent sessions.
	FindRecent(ctx context.Context, limit int) ([]*entities.SessionRecord, error)

	// FindBySignature retrieves all sessions for a given preset.
	FindBySignature(ctx context.Context, sigID uuid.UUID) ([]*entities.SessionRecord, error)

	// TotalListeningSeconds computes cumulative listening time across all sessions.
	TotalListeningSeconds(ctx context.Context) (float64, error)
}
