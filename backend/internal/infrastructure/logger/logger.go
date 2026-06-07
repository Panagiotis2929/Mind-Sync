// Package logger provides a structured, leveled logger built on uber-go/zap.
// It wraps zap.Logger with Mind-Sync-specific fields and a clean interface.
package logger

import (
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// Logger is the application-wide structured logger interface.
type Logger interface {
	Info(msg string, fields ...zap.Field)
	Warn(msg string, fields ...zap.Field)
	Error(msg string, fields ...zap.Field)
	Debug(msg string, fields ...zap.Field)
	Fatal(msg string, fields ...zap.Field)
	With(fields ...zap.Field) Logger
}

type zapLogger struct {
	z *zap.Logger
}

// New creates a production-ready zap logger with ISO8601 timestamps and JSON output.
func New(debug bool) (Logger, error) {
	var cfg zap.Config
	if debug {
		cfg = zap.NewDevelopmentConfig()
		cfg.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	} else {
		cfg = zap.NewProductionConfig()
		cfg.EncoderConfig.TimeKey = "timestamp"
		cfg.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	}

	z, err := cfg.Build(zap.AddCallerSkip(1))
	if err != nil {
		return nil, err
	}

	return &zapLogger{z: z.Named("mind-sync")}, nil
}

func (l *zapLogger) Info(msg string, fields ...zap.Field)  { l.z.Info(msg, fields...) }
func (l *zapLogger) Warn(msg string, fields ...zap.Field)  { l.z.Warn(msg, fields...) }
func (l *zapLogger) Error(msg string, fields ...zap.Field) { l.z.Error(msg, fields...) }
func (l *zapLogger) Debug(msg string, fields ...zap.Field) { l.z.Debug(msg, fields...) }
func (l *zapLogger) Fatal(msg string, fields ...zap.Field) { l.z.Fatal(msg, fields...) }

func (l *zapLogger) With(fields ...zap.Field) Logger {
	return &zapLogger{z: l.z.With(fields...)}
}
