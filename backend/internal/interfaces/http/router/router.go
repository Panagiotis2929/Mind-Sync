// Package router assembles the complete HTTP routing tree for the Mind-Sync API.
package router

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/mind-sync/neural-audio-architect/internal/infrastructure/logger"
	"github.com/mind-sync/neural-audio-architect/internal/interfaces/http/handlers"
	appmiddleware "github.com/mind-sync/neural-audio-architect/internal/interfaces/http/middleware"
)

// Dependencies groups all handler dependencies for the router.
type Dependencies struct {
	BlueprintHandler *handlers.BlueprintHandler
	SignatureHandler *handlers.SignatureHandler
	SessionHandler   *handlers.SessionHandler
	Logger           logger.Logger
}

// New constructs and returns the fully wired chi.Router.
func New(deps Dependencies) http.Handler {
	r := chi.NewRouter()

	// --- Global middleware stack (applied to every request) ---
	r.Use(appmiddleware.RequestID)
	r.Use(appmiddleware.RequestLogger(deps.Logger))
	r.Use(appmiddleware.Recoverer(deps.Logger))
	r.Use(chimiddleware.Compress(5)) // gzip compression

	// CORS: allow the Flutter web dev server and any localhost origin
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:*", "http://127.0.0.1:*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-Request-ID"},
		ExposedHeaders:   []string{"X-Request-ID"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	// --- Health check (no versioning prefix — infra concern) ---
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok","service":"mind-sync-neural-audio-architect"}`))
	})

	// --- API v1 routes ---
	r.Route("/api/v1", func(r chi.Router) {

		// DSP Blueprint computation
		r.Route("/blueprint", func(r chi.Router) {
			r.Post("/compute", deps.BlueprintHandler.Compute)
			r.Get("/presets", deps.BlueprintHandler.Presets)
		})

		// Neural Signature (saved presets) CRUD
		r.Route("/signatures", func(r chi.Router) {
			r.Get("/", deps.SignatureHandler.GetAll)
			r.Post("/", deps.SignatureHandler.Create)
			r.Route("/{id}", func(r chi.Router) {
				r.Get("/", deps.SignatureHandler.GetByID)
				r.Delete("/", deps.SignatureHandler.Delete)
				r.Post("/favorite", deps.SignatureHandler.ToggleFavorite)
			})
		})

		// Session tracking
		r.Route("/sessions", func(r chi.Router) {
			r.Get("/", deps.SessionHandler.GetRecent)
			r.Post("/", deps.SessionHandler.Start)
			r.Get("/stats", deps.SessionHandler.GetStats)
			r.Patch("/{id}/finalize", deps.SessionHandler.Finalize)
		})
	})

	return r
}
