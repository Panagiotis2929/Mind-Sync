package usecases

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/mind-sync/neural-audio-architect/internal/application/dtos"
	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
	"github.com/mind-sync/neural-audio-architect/internal/domain/repositories"
)

// ManageSignaturesUseCase handles all neural preset (signature) operations.
type ManageSignaturesUseCase struct {
	repo repositories.NeuralSignatureRepository
}

// NewManageSignaturesUseCase injects the repository dependency.
func NewManageSignaturesUseCase(repo repositories.NeuralSignatureRepository) *ManageSignaturesUseCase {
	return &ManageSignaturesUseCase{repo: repo}
}

// Create validates and persists a new NeuralSignature.
func (uc *ManageSignaturesUseCase) Create(
	ctx context.Context,
	req *dtos.CreateSignatureRequest,
) (*dtos.NeuralSignatureDTO, error) {
	now := time.Now().UTC()
	sig := &entities.NeuralSignature{
		ID:           uuid.New(),
		Name:         strings.TrimSpace(req.Name),
		Description:  strings.TrimSpace(req.Description),
		SessionMode:  strings.ToUpper(req.SessionMode),
		FocusDepth:   req.FocusDepth,
		CalmLevel:    req.CalmLevel,
		EnergyLevel:  req.EnergyLevel,
		NoiseProfile: entities.NoiseProfile(strings.ToUpper(req.NoiseProfile)),
		NoiseVolume:  req.NoiseVolume,
		OscMode:      entities.OscillatorMode(strings.ToUpper(req.OscillatorMode)),
		MasterVolume: req.MasterVolume,
		Tags:         req.Tags,
		IsFavorite:   false,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	if err := sig.Validate(); err != nil {
		return nil, fmt.Errorf("domain validation: %w", err)
	}

	if err := uc.repo.Save(ctx, sig); err != nil {
		return nil, fmt.Errorf("persistence error: %w", err)
	}

	return mapSignatureToDTO(sig), nil
}

// GetAll retrieves all saved signatures ordered by most recently updated.
func (uc *ManageSignaturesUseCase) GetAll(ctx context.Context) ([]*dtos.NeuralSignatureDTO, error) {
	sigs, err := uc.repo.FindAll(ctx)
	if err != nil {
		return nil, fmt.Errorf("repository error: %w", err)
	}

	dtoList := make([]*dtos.NeuralSignatureDTO, len(sigs))
	for i, s := range sigs {
		dtoList[i] = mapSignatureToDTO(s)
	}
	return dtoList, nil
}

// GetByID retrieves a single signature by UUID string.
func (uc *ManageSignaturesUseCase) GetByID(ctx context.Context, idStr string) (*dtos.NeuralSignatureDTO, error) {
	id, err := uuid.Parse(idStr)
	if err != nil {
		return nil, fmt.Errorf("invalid UUID '%s': %w", idStr, err)
	}

	sig, err := uc.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	return mapSignatureToDTO(sig), nil
}

// Delete removes a signature permanently.
func (uc *ManageSignaturesUseCase) Delete(ctx context.Context, idStr string) error {
	id, err := uuid.Parse(idStr)
	if err != nil {
		return fmt.Errorf("invalid UUID '%s': %w", idStr, err)
	}
	return uc.repo.Delete(ctx, id)
}

// ToggleFavorite flips the favorite status of a signature.
func (uc *ManageSignaturesUseCase) ToggleFavorite(ctx context.Context, idStr string) error {
	id, err := uuid.Parse(idStr)
	if err != nil {
		return fmt.Errorf("invalid UUID '%s': %w", idStr, err)
	}
	return uc.repo.ToggleFavorite(ctx, id)
}

// mapSignatureToDTO translates a domain entity to a transport DTO.
func mapSignatureToDTO(sig *entities.NeuralSignature) *dtos.NeuralSignatureDTO {
	tags := sig.Tags
	if tags == nil {
		tags = []string{}
	}
	return &dtos.NeuralSignatureDTO{
		ID:             sig.ID.String(),
		Name:           sig.Name,
		Description:    sig.Description,
		SessionMode:    sig.SessionMode,
		FocusDepth:     sig.FocusDepth,
		CalmLevel:      sig.CalmLevel,
		EnergyLevel:    sig.EnergyLevel,
		NoiseProfile:   string(sig.NoiseProfile),
		NoiseVolume:    sig.NoiseVolume,
		OscillatorMode: string(sig.OscMode),
		MasterVolume:   sig.MasterVolume,
		Tags:           tags,
		IsFavorite:     sig.IsFavorite,
		CreatedAt:      sig.CreatedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:      sig.UpdatedAt.Format("2006-01-02T15:04:05Z"),
	}
}
