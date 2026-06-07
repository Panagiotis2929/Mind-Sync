package usecases

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/mind-sync/neural-audio-architect/internal/application/dtos"
	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
	"github.com/mind-sync/neural-audio-architect/internal/domain/repositories"
)

// TrackSessionsUseCase manages the session lifecycle: start, finalize, and query.
type TrackSessionsUseCase struct {
	repo repositories.SessionRepository
	sigRepo repositories.NeuralSignatureRepository
}

// NewTrackSessionsUseCase injects required repositories.
func NewTrackSessionsUseCase(
	repo repositories.SessionRepository,
	sigRepo repositories.NeuralSignatureRepository,
) *TrackSessionsUseCase {
	return &TrackSessionsUseCase{repo: repo, sigRepo: sigRepo}
}

// StartSession creates a new session record at the moment audio playback begins.
func (uc *TrackSessionsUseCase) StartSession(
	ctx context.Context,
	req *dtos.CreateSessionRequest,
) (*dtos.SessionRecordDTO, error) {
	blueprintID, err := uuid.Parse(req.BlueprintID)
	if err != nil {
		return nil, fmt.Errorf("invalid blueprint_id: %w", err)
	}

	session := &entities.SessionRecord{
		ID:          uuid.New(),
		BlueprintID: blueprintID,
		SessionMode: req.SessionMode,
		StartedAt:   time.Now().UTC(),
	}

	// Optionally link to a saved signature
	if req.SignatureID != "" {
		sigID, err := uuid.Parse(req.SignatureID)
		if err != nil {
			return nil, fmt.Errorf("invalid signature_id: %w", err)
		}
		// Verify signature exists
		if _, err := uc.sigRepo.FindByID(ctx, sigID); err != nil {
			return nil, fmt.Errorf("signature not found: %w", err)
		}
		session.SignatureID = &sigID
	}

	if err := uc.repo.CreateSession(ctx, session); err != nil {
		return nil, fmt.Errorf("failed to create session: %w", err)
	}

	return mapSessionToDTO(session), nil
}

// FinalizeSession marks a session as completed with its actual listened duration.
func (uc *TrackSessionsUseCase) FinalizeSession(
	ctx context.Context,
	idStr string,
	req *dtos.FinalizeSessionRequest,
) error {
	id, err := uuid.Parse(idStr)
	if err != nil {
		return fmt.Errorf("invalid session_id: %w", err)
	}
	if req.DurationSec < 0 {
		return fmt.Errorf("duration_sec must be non-negative")
	}
	return uc.repo.FinalizeSession(ctx, id, req.DurationSec)
}

// GetRecentSessions retrieves the N most recent sessions.
func (uc *TrackSessionsUseCase) GetRecentSessions(ctx context.Context, limit int) ([]*dtos.SessionRecordDTO, error) {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	sessions, err := uc.repo.FindRecent(ctx, limit)
	if err != nil {
		return nil, fmt.Errorf("repository error: %w", err)
	}

	dtoList := make([]*dtos.SessionRecordDTO, len(sessions))
	for i, s := range sessions {
		dtoList[i] = mapSessionToDTO(s)
	}
	return dtoList, nil
}

// GetStats computes aggregate user statistics for the dashboard.
func (uc *TrackSessionsUseCase) GetStats(
	ctx context.Context,
	sigCount int,
) (*dtos.StatsDTO, error) {
	sessions, err := uc.repo.FindRecent(ctx, 1000)
	if err != nil {
		return nil, err
	}

	totalListeningSec, err := uc.repo.TotalListeningSeconds(ctx)
	if err != nil {
		return nil, err
	}

	// Tally most-used session mode
	modeCounts := map[string]int{}
	for _, s := range sessions {
		modeCounts[s.SessionMode]++
	}
	favMode := "FOCUS"
	maxCount := 0
	for mode, count := range modeCounts {
		if count > maxCount {
			maxCount = count
			favMode = mode
		}
	}

	return &dtos.StatsDTO{
		TotalSessions:     len(sessions),
		TotalListeningSec: totalListeningSec,
		FavoriteMode:      favMode,
		SavedSignatures:   sigCount,
	}, nil
}

// mapSessionToDTO translates a domain SessionRecord to an API DTO.
func mapSessionToDTO(s *entities.SessionRecord) *dtos.SessionRecordDTO {
	dto := &dtos.SessionRecordDTO{
		ID:              s.ID.String(),
		BlueprintID:     s.BlueprintID.String(),
		SessionMode:     s.SessionMode,
		BrainwaveTarget: string(s.BrainwaveTarget),
		StartedAt:       s.StartedAt.Format("2006-01-02T15:04:05Z"),
		DurationSec:     s.DurationSec,
		Notes:           s.Notes,
	}
	if s.SignatureID != nil {
		dto.SignatureID = s.SignatureID.String()
	}
	if s.EndedAt != nil {
		dto.EndedAt = s.EndedAt.Format("2006-01-02T15:04:05Z")
	}
	return dto
}
