.PHONY: all build run test lint tidy clean

BINARY_NAME := mind-sync-server
BUILD_DIR   := ./build
CMD_PATH    := ./cmd/server

all: tidy build

## build: Compile the server binary
build:
	@echo "→ Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=1 go build -ldflags="-s -w" -o $(BUILD_DIR)/$(BINARY_NAME) $(CMD_PATH)
	@echo "✓ Built: $(BUILD_DIR)/$(BINARY_NAME)"

## run: Run the server in development mode
run:
	@echo "→ Starting Mind-Sync server on :8080..."
	DEBUG=true CGO_ENABLED=1 go run $(CMD_PATH)/main.go

## test: Run all tests with race detection
test:
	CGO_ENABLED=1 go test -race -cover ./...

## tidy: Sync go.mod and go.sum
tidy:
	go mod tidy

## lint: Run golangci-lint (must be installed)
lint:
	golangci-lint run ./...

## clean: Remove build artifacts and the local SQLite database
clean:
	rm -rf $(BUILD_DIR) ./data/mind_sync.db

## help: Print this help message
help:
	@grep -E '^##' Makefile | sed 's/## //'
