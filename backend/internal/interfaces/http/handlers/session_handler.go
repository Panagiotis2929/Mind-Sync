package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/mind-sync/neural-audio-architect/internal/application/dtos"
	"github.com/mind-sync/neural-audio-architect/internal/application/usecases"
	"github.com/mind-sync/neural-audio-architect/internal/infrastructure/logger"
	"go.uber.org/zap"
)

// SessionHandler handles all /api/v1/sessions endpoints.
type SessionHandler struct {
	uc    *usecases.TrackSessionsUseCase
	sigUC *usecases.ManageSignaturesUseCase
	log   logger.Logger
}

// NewSessionHandler creates the handler with required use cases.
func NewSessionHandler(
	uc *usecases.TrackSessionsUseCase,
	sigUC *usecases.ManageSignaturesUseCase,
	log logger.Logger,
) *SessionHandler {
	return &SessionHandler{uc: uc, sigUC: sigUC, log: log}
}

// Start handles POST /api/v1/sessions
// Called when the user begins a listening session.
func (h *SessionHandler) Start(w http.ResponseWriter, r *http.Request) {
	var req dtos.CreateSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondBadRequest(w, "Invalid JSON body: "+err.Error())
		return
	}
	defer r.Body.Close()

	session, err := h.uc.StartSession(r.Context(), &req)
	if err != nil {
		h.log.Warn("session start failed", zap.Error(err))
		if isDomainValidation(err) || isNotFound(err) {
			respondBadRequest(w, err.Error())
			return
		}
		respondInternalError(w)
		return
	}

	h.log.Info("session started", zap.String("id", session.ID), zap.String("mode", session.SessionMode))
	respondCreated(w, session)
}

// Finalize handles PATCH /api/v1/sessions/{id}/finalize
// Called when the user stops or the session timer expires.
func (h *SessionHandler) Finalize(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var req dtos.FinalizeSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondBadRequest(w, "Invalid JSON body: "+err.Error())
		return
	}
	defer r.Body.Close()

	if err := h.uc.FinalizeSession(r.Context(), id, &req); err != nil {
		if isNotFound(err) {
			respondNotFound(w, "Session not found: "+id)
			return
		}
		h.log.Error("session finalize failed", zap.String("id", id), zap.Error(err))
		respondInternalError(w)
		return
	}

	h.log.Info("session finalized",
		zap.String("id", id),
		zap.Float64("duration_sec", req.DurationSec),
	)
	respondOK(w, map[string]string{"status": "finalized"})
}

// GetRecent handles GET /api/v1/sessions?limit=N
func (h *SessionHandler) GetRecent(w http.ResponseWriter, r *http.Request) {
	limitStr := r.URL.Query().Get("limit")
	limit := 20
	if limitStr != "" {
		if n, err := strconv.Atoi(limitStr); err == nil && n > 0 {
			limit = n
		}
	}

	sessions, err := h.uc.GetRecentSessions(r.Context(), limit)
	if err != nil {
		h.log.Error("failed to list sessions", zap.Error(err))
		respondInternalError(w)
		return
	}

	respondOKWithMeta(w, sessions, &APIMeta{Count: len(sessions)})
}

// GetStats handles GET /api/v1/sessions/stats
func (h *SessionHandler) GetStats(w http.ResponseWriter, r *http.Request) {
	sigs, err := h.sigUC.GetAll(r.Context())
	if err != nil {
		h.log.Error("failed to count signatures", zap.Error(err))
		respondInternalError(w)
		return
	}

	stats, err := h.uc.GetStats(r.Context(), len(sigs))
	if err != nil {
		h.log.Error("failed to compute stats", zap.Error(err))
		respondInternalError(w)
		return
	}

	respondOK(w, stats)
}
