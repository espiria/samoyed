# Makefile for Samoyed
# Provides convenient commands for building, testing, and development

.PHONY: help build test test-docker test-docker-parallel test-docker-compose clean

# Default target
help:
	@echo "Samoyed - Git hooks manager"
	@echo ""
	@echo "Available targets:"
	@echo "  make build                 - Build release binary"
	@echo "  make test                  - Run unit tests"
	@echo "  make test-integration      - Run integration tests (serial)"
	@echo "  make test-docker           - Run integration tests in Docker (serial)"
	@echo "  make test-docker-parallel  - Run integration tests in Docker (parallel)"
	@echo "  make test-docker-compose   - Run integration tests via Docker Compose"
	@echo "  make clean                 - Clean build artifacts"
	@echo "  make fmt                   - Format code"
	@echo "  make clippy                - Run Clippy linter"
	@echo "  make coverage              - Generate test coverage report"

# Build release binary
build:
	cargo build --release --verbose

# Run Rust unit tests
test:
	cargo test --verbose -- --test-threads=1

# Run integration tests locally (serial)
test-integration: build
	@echo "Running integration tests..."
	@cd tests/integration && for test in [0-9]*.sh; do \
		echo "Running $$test..."; \
		./$$test || exit 1; \
	done

# Build and test in Docker (serial)
test-docker:
	docker build -t samoyed-test:latest -f Dockerfile .
	@for test in tests/integration/[0-9]*.sh; do \
		test_name=$$(basename $$test); \
		echo "Running $$test_name in Docker..."; \
		docker run --rm -e TEST_NAME=$$test_name samoyed-test:latest || exit 1; \
	done

# Build and test in Docker (parallel)
test-docker-parallel:
	@bash tests/integration/run-parallel-docker.sh

# Test using Docker Compose
test-docker-compose:
	docker-compose -f docker-compose.test.yml build
	docker-compose -f docker-compose.test.yml up --abort-on-container-exit --exit-code-from test-01-default
	docker-compose -f docker-compose.test.yml down

# Clean build artifacts
clean:
	cargo clean
	rm -rf target/
	rm -f *.log

# Format code
fmt:
	cargo fmt --all

# Run Clippy linter
clippy:
	cargo clippy --all-targets --all-features -- -D warnings

# Generate test coverage
coverage:
	cargo tarpaulin -- --test-threads=1
