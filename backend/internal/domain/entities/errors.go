package entities

import "fmt"

// Domain-level sentinel errors. These are intentionally distinct from
// infrastructure or application-level errors to preserve clean architecture layers.

// DomainError wraps a domain invariant violation with a stable code.
type DomainError struct {
	Code    string
	Message string
}

func (e *DomainError) Error() string {
	return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

var (
	ErrInvalidSignatureName = &DomainError{
		Code:    "INVALID_SIGNATURE_NAME",
		Message: "neural signature must have a non-empty name",
	}
	ErrSignatureNotFound = &DomainError{
		Code:    "SIGNATURE_NOT_FOUND",
		Message: "neural signature not found",
	}
	ErrSessionNotFound = &DomainError{
		Code:    "SESSION_NOT_FOUND",
		Message: "session record not found",
	}
	ErrBlueprintComputationFailed = &DomainError{
		Code:    "BLUEPRINT_COMPUTATION_FAILED",
		Message: "DSP engine failed to compute neural blueprint",
	}
)

// ErrParameterOutOfRange constructs a typed range violation error.
func ErrParameterOutOfRange(param string, value float64) *DomainError {
	return &DomainError{
		Code:    "PARAMETER_OUT_OF_RANGE",
		Message: fmt.Sprintf("parameter '%s' = %.4f is outside [0.0, 1.0]", param, value),
	}
}
