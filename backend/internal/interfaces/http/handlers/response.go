package handlers

import (
	"encoding/json"
	"net/http"
)

// APIResponse is the standard JSON envelope for all Mind-Sync API responses.
type APIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *APIError   `json:"error,omitempty"`
	Meta    *APIMeta    `json:"meta,omitempty"`
}

// APIError carries a machine-readable code and a human-readable message.
type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

// APIMeta carries optional pagination or timing metadata.
type APIMeta struct {
	Count     int    `json:"count,omitempty"`
	RequestID string `json:"request_id,omitempty"`
}

// writeJSON encodes v as JSON with the given status code.
// It always sets Content-Type: application/json.
func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	enc := json.NewEncoder(w)
	enc.SetEscapeHTML(false)
	_ = enc.Encode(v)
}

// respondOK sends a 200 OK with a data payload.
func respondOK(w http.ResponseWriter, data interface{}) {
	writeJSON(w, http.StatusOK, APIResponse{Success: true, Data: data})
}

// respondOKWithMeta sends a 200 OK with data and metadata (e.g. count).
func respondOKWithMeta(w http.ResponseWriter, data interface{}, meta *APIMeta) {
	writeJSON(w, http.StatusOK, APIResponse{Success: true, Data: data, Meta: meta})
}

// respondCreated sends a 201 Created with the new resource.
func respondCreated(w http.ResponseWriter, data interface{}) {
	writeJSON(w, http.StatusCreated, APIResponse{Success: true, Data: data})
}

// respondNoContent sends a 204 No Content (for deletes).
func respondNoContent(w http.ResponseWriter) {
	w.WriteHeader(http.StatusNoContent)
}

// respondError sends a structured error response.
func respondError(w http.ResponseWriter, status int, code, message string) {
	writeJSON(w, status, APIResponse{
		Success: false,
		Error:   &APIError{Code: code, Message: message},
	})
}

// respondBadRequest is a convenience wrapper for 400.
func respondBadRequest(w http.ResponseWriter, message string) {
	respondError(w, http.StatusBadRequest, "BAD_REQUEST", message)
}

// respondNotFound is a convenience wrapper for 404.
func respondNotFound(w http.ResponseWriter, message string) {
	respondError(w, http.StatusNotFound, "NOT_FOUND", message)
}

// respondInternalError is a convenience wrapper for 500.
func respondInternalError(w http.ResponseWriter) {
	respondError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "An unexpected error occurred")
}
