package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/mind-sync/neural-audio-architect/internal/application/dtos"
	"github.com/mind-sync/neural-audio-architect/internal/application/usecases"
	"github.com/mind-sync/neural-audio-architect/internal/domain/entities"
	"github.com/mind-sync/neural-audio-architect/internal/infrastructure/logger"
	"go.uber.org/zap"
)

// SignatureHandler handles all /api/v1/signatures endpoints.
type SignatureHandler struct {
	uc  *usecases.ManageSignaturesUseCase
	log logger.Logger
}

// NewSignatureHandler creates the handler with its required use case.
func NewSignatureHandler(uc *usecases.ManageSignaturesUseCase, log logger.Logger) *SignatureHandler {
	return &SignatureHandler{uc: uc, log: log}
}

// Create handles POST /api/v1/signatures
func (h *SignatureHandler) Create(w http.ResponseWriter, r *http.Request) {
	var req dtos.CreateSignatureRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondBadRequest(w, "Invalid JSON body: "+err.Error())
		return
	}
	defer r.Body.Close()

	sig, err := h.uc.Create(r.Context(), &req)
	if err != nil {
		h.log.Warn("signature creation failed", zap.Error(err))
		if isDomainValidation(err) {
			respondBadRequest(w, err.Error())
			return
		}
		respondInternalError(w)
		return
	}

	h.log.Info("signature created", zap.String("id", sig.ID), zap.String("name", sig.Name))
	respondCreated(w, sig)
}

// GetAll handles GET /api/v1/signatures
func (h *SignatureHandler) GetAll(w http.ResponseWriter, r *http.Request) {
	sigs, err := h.uc.GetAll(r.Context())
	if err != nil {
		h.log.Error("failed to list signatures", zap.Error(err))
		respondInternalError(w)
		return
	}

	respondOKWithMeta(w, sigs, &APIMeta{Count: len(sigs)})
}

// GetByID handles GET /api/v1/signatures/{id}
func (h *SignatureHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	sig, err := h.uc.GetByID(r.Context(), id)
	if err != nil {
		if isNotFound(err) {
			respondNotFound(w, "Signature not found: "+id)
			return
		}
		respondBadRequest(w, err.Error())
		return
	}
	respondOK(w, sig)
}

// Delete handles DELETE /api/v1/signatures/{id}
func (h *SignatureHandler) Delete(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.uc.Delete(r.Context(), id); err != nil {
		if isNotFound(err) {
			respondNotFound(w, "Signature not found: "+id)
			return
		}
		h.log.Error("signature delete failed", zap.String("id", id), zap.Error(err))
		respondInternalError(w)
		return
	}

	h.log.Info("signature deleted", zap.String("id", id))
	respondNoContent(w)
}

// ToggleFavorite handles POST /api/v1/signatures/{id}/favorite
func (h *SignatureHandler) ToggleFavorite(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.uc.ToggleFavorite(r.Context(), id); err != nil {
		if isNotFound(err) {
			respondNotFound(w, "Signature not found: "+id)
			return
		}
		respondInternalError(w)
		return
	}
	respondOK(w, map[string]string{"status": "toggled"})
}

// --- Error classification helpers ---

func isDomainValidation(err error) bool {
	if de, ok := err.(*entities.DomainError); ok {
		_ = de
		return true
	}
	msg := err.Error()
	return strings.Contains(msg, "validation") ||
		strings.Contains(msg, "out of range") ||
		strings.Contains(msg, "invalid")
}

func isNotFound(err error) bool {
	if de, ok := err.(*entities.DomainError); ok {
		return de.Code == "SIGNATURE_NOT_FOUND" || de.Code == "SESSION_NOT_FOUND"
	}
	return strings.Contains(strings.ToLower(err.Error()), "not found")
}
