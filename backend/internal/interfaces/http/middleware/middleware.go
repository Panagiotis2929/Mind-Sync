// Package middleware provides HTTP middleware for the Mind-Sync API server.
package middleware

import (
	"fmt"
	"net/http"
	"runtime/debug"
	"time"

	"github.com/google/uuid"
	"github.com/mind-sync/neural-audio-architect/internal/infrastructure/logger"
	"go.uber.org/zap"
)

const requestIDHeader = "X-Request-ID"

// RequestID injects a unique request ID into every inbound request's header.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get(requestIDHeader)
		if id == "" {
			id = uuid.New().String()
		}
		w.Header().Set(requestIDHeader, id)
		r.Header.Set(requestIDHeader, id)
		next.ServeHTTP(w, r)
	})
}

// responseWriter is a minimal wrapper around http.ResponseWriter to capture status codes.
type responseWriter struct {
	http.ResponseWriter
	status      int
	wroteHeader bool
}

func (rw *responseWriter) WriteHeader(code int) {
	if rw.wroteHeader {
		return
	}
	rw.status = code
	rw.wroteHeader = true
	rw.ResponseWriter.WriteHeader(code)
}

// RequestLogger logs each request with method, path, status, latency, and request ID.
func RequestLogger(log logger.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			rw := &responseWriter{ResponseWriter: w, status: http.StatusOK}

			next.ServeHTTP(rw, r)

			log.Info("http request",
				zap.String("method", r.Method),
				zap.String("path", r.URL.Path),
				zap.Int("status", rw.status),
				zap.Duration("latency", time.Since(start)),
				zap.String("request_id", r.Header.Get(requestIDHeader)),
				zap.String("remote_addr", r.RemoteAddr),
			)
		})
	}
}

// Recoverer catches panics, logs them with a stack trace, and returns 500.
func Recoverer(log logger.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if rec := recover(); rec != nil {
					log.Error("unhandled panic",
						zap.String("panic", fmt.Sprintf("%v", rec)),
						zap.String("stack", string(debug.Stack())),
						zap.String("request_id", r.Header.Get(requestIDHeader)),
					)
					http.Error(w,
						`{"error":"internal_server_error","message":"An unexpected error occurred"}`,
						http.StatusInternalServerError,
					)
				}
			}()
			next.ServeHTTP(w, r)
		})
	}
}
