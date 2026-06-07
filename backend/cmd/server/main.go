// Package main is the entrypoint for the Mind-Sync Neural Audio Architect backend.
// It wires the dependency graph, configures the server, and manages lifecycle.
package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"github.com/mind-sync/neural-audio-architect/internal/application/usecases"
	"github.com/mind-sync/neural-audio-architect/internal/infrastructure/logger"
	"github.com/mind-sync/neural-audio-architect/internal/infrastructure/persistence"
	"github.com/mind-sync/neural-audio-architect/internal/interfaces/http/handlers"
	"github.com/mind-sync/neural-audio-architect/internal/interfaces/http/router"
	"github.com/mind-sync/neural-audio-architect/pkg/dsp"
	"go.uber.org/zap"
)

const (
	defaultPort    = "8080"
	defaultDataDir = "./data"
	dbFilename     = "mind_sync.db"
	shutdownTimeout = 10 * time.Second
)

func main() {
	// ── 1. Logger ──────────────────────────────────────────────────────────
	debug := os.Getenv("DEBUG") == "true"
	log, err := logger.New(debug)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to initialize logger: %v\n", err)
		os.Exit(1)
	}
	log.Info("starting Mind-Sync Neural Audio Architect",
		zap.String("version", "1.0.0"),
		zap.Bool("debug", debug),
	)

	// ── 2. Data directory ─────────────────────────────────────────────────
	dataDir := envOrDefault("DATA_DIR", defaultDataDir)
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		log.Fatal("failed to create data directory", zap.Error(err))
	}
	dbPath := filepath.Join(dataDir, dbFilename)

	// ── 3. Database ───────────────────────────────────────────────────────
	db, err := persistence.NewSQLiteDB(dbPath)
	if err != nil {
		log.Fatal("failed to initialize SQLite", zap.Error(err), zap.String("path", dbPath))
	}
	defer db.Close()
	log.Info("SQLite initialized", zap.String("path", dbPath))

	// ── 4. Repositories ───────────────────────────────────────────────────
	sigRepo := persistence.NewSQLiteSignatureRepository(db)
	sessRepo := persistence.NewSQLiteSessionRepository(db)

	// ── 5. DSP Engine ─────────────────────────────────────────────────────
	dspEngine := dsp.NewEngine()
	log.Info("DSP engine initialized", zap.String("sample_rate", "44100 Hz"), zap.String("bit_depth", "32-bit"))

	// ── 6. Use Cases ──────────────────────────────────────────────────────
	computeBlueprintUC := usecases.NewComputeBlueprintUseCase(dspEngine)
	manageSignaturesUC := usecases.NewManageSignaturesUseCase(sigRepo)
	trackSessionsUC := usecases.NewTrackSessionsUseCase(sessRepo, sigRepo)

	// ── 7. Handlers ───────────────────────────────────────────────────────
	blueprintHandler := handlers.NewBlueprintHandler(computeBlueprintUC, log)
	signatureHandler := handlers.NewSignatureHandler(manageSignaturesUC, log)
	sessionHandler := handlers.NewSessionHandler(trackSessionsUC, manageSignaturesUC, log)

	// ── 8. Router ─────────────────────────────────────────────────────────
	httpHandler := router.New(router.Dependencies{
		BlueprintHandler: blueprintHandler,
		SignatureHandler:  signatureHandler,
		SessionHandler:   sessionHandler,
		Logger:           log,
	})

	// ── 9. HTTP Server ────────────────────────────────────────────────────
	port := envOrDefault("PORT", defaultPort)
	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           httpHandler,
		ReadTimeout:       5 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
		ReadHeaderTimeout: 2 * time.Second,
	}

	// ── 10. Start + Graceful Shutdown ─────────────────────────────────────
	errChan := make(chan error, 1)
	go func() {
		log.Info("HTTP server listening", zap.String("addr", srv.Addr))
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errChan <- err
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-errChan:
		log.Fatal("server error", zap.Error(err))
	case sig := <-quit:
		log.Info("shutdown signal received", zap.String("signal", sig.String()))
	}

	ctx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Error("graceful shutdown failed", zap.Error(err))
	} else {
		log.Info("server shutdown complete")
	}
}

func envOrDefault(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
