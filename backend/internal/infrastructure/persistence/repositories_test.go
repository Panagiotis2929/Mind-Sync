package persistence_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
	"github.com/mind-sync/neural-audio-architect/internal/infrastructure/persistence"
)

func setupTestDB(t *testing.T) (*persistence.SQLiteSignatureRepository, *persistence.SQLiteSessionRepository, func()) {
	t.Helper()

	// Use a temp file so each test gets a clean, isolated database
	f, err := os.CreateTemp("", "mind_sync_test_*.db")
	if err != nil {
		t.Fatalf("failed to create temp db file: %v", err)
	}
	f.Close()

	db, err := persistence.NewSQLiteDB(f.Name())
	if err != nil {
		t.Fatalf("failed to init SQLite: %v", err)
	}

	sigRepo  := persistence.NewSQLiteSignatureRepository(db)
	sessRepo := persistence.NewSQLiteSessionRepository(db)

	cleanup := func() {
		db.Close()
		os.Remove(f.Name())
	}

	return sigRepo, sessRepo, cleanup
}

func makeSignature(name string) *entities.NeuralSignature {
	now := time.Now().UTC()
	return &entities.NeuralSignature{
		ID:           uuid.New(),
		Name:         name,
		Description:  "Test signature",
		SessionMode:  "FOCUS",
		FocusDepth:   0.75,
		CalmLevel:    0.40,
		EnergyLevel:  0.65,
		NoiseProfile: entities.NoisePink,
		NoiseVolume:  0.25,
		OscMode:      entities.OscillatorBinaural,
		MasterVolume: 0.70,
		Tags:         []string{"test", "unit"},
		IsFavorite:   false,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
}

// ── Signature repository tests ────────────────────────────────────────────

func TestSignatureRepo_SaveAndFindByID(t *testing.T) {
	repo, _, cleanup := setupTestDB(t)
	defer cleanup()

	ctx := context.Background()
	sig := makeSignature("Deep Focus")

	if err := repo.Save(ctx, sig); err != nil {
		t.Fatalf("Save failed: %v", err)
	}

	found, err := repo.FindByID(ctx, sig.ID)
	if err != nil {
		t.Fatalf("FindByID failed: %v", err)
	}

	if found.Name != sig.Name {
		t.Errorf("name mismatch: got %q, want %q", found.Name, sig.Name)
	}
	if found.FocusDepth != sig.FocusDepth {
		t.Errorf("focus_depth mismatch: got %.4f, want %.4f", found.FocusDepth, sig.FocusDepth)
	}
	if len(found.Tags) != 2 {
		t.Errorf("tags not persisted: got %v", found.Tags)
	}
}

func TestSignatureRepo_FindAll_ReturnsMostRecentFirst(t *testing.T) {
	repo, _, cleanup := setupTestDB(t)
	defer cleanup()
	ctx := context.Background()

	names := []string{"Alpha", "Beta", "Gamma"}
	for i, name := range names {
		sig := makeSignature(name)
		sig.UpdatedAt = sig.UpdatedAt.Add(time.Duration(i) * time.Second)
		if err := repo.Save(ctx, sig); err != nil {
			t.Fatalf("Save failed: %v", err)
		}
	}

	all, err := repo.FindAll(ctx)
	if err != nil {
		t.Fatalf("FindAll failed: %v", err)
	}
	if len(all) != 3 {
		t.Fatalf("expected 3 signatures, got %d", len(all))
	}
	// Most recently updated should be first
	if all[0].Name != "Gamma" {
		t.Errorf("expected Gamma first, got %s", all[0].Name)
	}
}

func TestSignatureRepo_Delete_RemovesRecord(t *testing.T) {
	repo, _, cleanup := setupTestDB(t)
	defer cleanup()
	ctx := context.Background()

	sig := makeSignature("Ephemeral")
	repo.Save(ctx, sig) //nolint:errcheck

	if err := repo.Delete(ctx, sig.ID); err != nil {
		t.Fatalf("Delete failed: %v", err)
	}

	_, err := repo.FindByID(ctx, sig.ID)
	if err == nil {
		t.Error("expected error after deletion, got nil")
	}
}

func TestSignatureRepo_Delete_NotFound_ReturnsError(t *testing.T) {
	repo, _, cleanup := setupTestDB(t)
	defer cleanup()

	err := repo.Delete(context.Background(), uuid.New()) // random ID
	if err == nil {
		t.Error("expected not-found error, got nil")
	}
}

func TestSignatureRepo_ToggleFavorite(t *testing.T) {
	repo, _, cleanup := setupTestDB(t)
	defer cleanup()
	ctx := context.Background()

	sig := makeSignature("Toggle Me")
	repo.Save(ctx, sig) //nolint:errcheck

	// Toggle on
	if err := repo.ToggleFavorite(ctx, sig.ID); err != nil {
		t.Fatalf("ToggleFavorite (on) failed: %v", err)
	}
	found, _ := repo.FindByID(ctx, sig.ID)
	if !found.IsFavorite {
		t.Error("expected IsFavorite=true after first toggle")
	}

	// Toggle off
	repo.ToggleFavorite(ctx, sig.ID) //nolint:errcheck
	found, _ = repo.FindByID(ctx, sig.ID)
	if found.IsFavorite {
		t.Error("expected IsFavorite=false after second toggle")
	}
}

// ── Session repository tests ──────────────────────────────────────────────

func TestSessionRepo_CreateAndFindByID(t *testing.T) {
	_, sessRepo, cleanup := setupTestDB(t)
	defer cleanup()
	ctx := context.Background()

	session := &entities.SessionRecord{
		ID:          uuid.New(),
		BlueprintID: uuid.New(),
		SessionMode: "FOCUS",
		StartedAt:   time.Now().UTC(),
	}

	if err := sessRepo.CreateSession(ctx, session); err != nil {
		t.Fatalf("CreateSession failed: %v", err)
	}

	found, err := sessRepo.FindByID(ctx, session.ID)
	if err != nil {
		t.Fatalf("FindByID failed: %v", err)
	}
	if found.SessionMode != "FOCUS" {
		t.Errorf("session mode mismatch: got %s", found.SessionMode)
	}
}

func TestSessionRepo_FinalizeSession_UpdatesDuration(t *testing.T) {
	_, sessRepo, cleanup := setupTestDB(t)
	defer cleanup()
	ctx := context.Background()

	session := &entities.SessionRecord{
		ID:          uuid.New(),
		BlueprintID: uuid.New(),
		SessionMode: "SLEEP",
		StartedAt:   time.Now().UTC(),
	}
	sessRepo.CreateSession(ctx, session) //nolint:errcheck

	const expectedDuration = 1847.5
	if err := sessRepo.FinalizeSession(ctx, session.ID, expectedDuration); err != nil {
		t.Fatalf("FinalizeSession failed: %v", err)
	}

	found, _ := sessRepo.FindByID(ctx, session.ID)
	if found.DurationSec != expectedDuration {
		t.Errorf("duration: got %.1f, want %.1f", found.DurationSec, expectedDuration)
	}
	if found.EndedAt == nil {
		t.Error("ended_at should be set after finalization")
	}
}

func TestSessionRepo_TotalListeningSeconds_Sums(t *testing.T) {
	_, sessRepo, cleanup := setupTestDB(t)
	defer cleanup()
	ctx := context.Background()

	durations := []float64{300, 600, 1200}
	for _, dur := range durations {
		s := &entities.SessionRecord{
			ID:          uuid.New(),
			BlueprintID: uuid.New(),
			SessionMode: "FOCUS",
			StartedAt:   time.Now().UTC(),
		}
		sessRepo.CreateSession(ctx, s)               //nolint:errcheck
		sessRepo.FinalizeSession(ctx, s.ID, dur)     //nolint:errcheck
	}

	total, err := sessRepo.TotalListeningSeconds(ctx)
	if err != nil {
		t.Fatalf("TotalListeningSeconds failed: %v", err)
	}
	expected := 300.0 + 600.0 + 1200.0
	if total != expected {
		t.Errorf("total: got %.1f, want %.1f", total, expected)
	}
}
