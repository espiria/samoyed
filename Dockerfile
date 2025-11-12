# Dockerfile for Samoyed integration tests
# Multi-stage build for efficient parallel testing

# Stage 1: Build Samoyed binary
FROM rust:1.83-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency files first (better caching)
COPY Cargo.toml Cargo.lock ./
COPY src ./src
COPY assets ./assets
COPY clippy.toml ./

# Build release binary
RUN cargo build --release --verbose && \
    strip target/release/samoyed

# Stage 2: Test runtime environment
FROM debian:bookworm-slim AS test-runner

# Install minimal dependencies for tests
RUN apt-get update && \
    apt-get install -y \
        git \
        bash \
        coreutils \
        ca-certificates \
        procps \
    && rm -rf /var/lib/apt/lists/*

# Configure git for tests (disable commit signing)
RUN git config --global commit.gpgsign false && \
    git config --global user.email "test@samoyed.test" && \
    git config --global user.name "Samoyed Test"

# Copy compiled binary from builder
COPY --from=builder /build/target/release/samoyed /usr/local/bin/samoyed

# Copy test suite
COPY tests/integration /tests/integration

# Set up test workspace (isolated per container)
WORKDIR /test-workspace

# Verify binary works
RUN samoyed --version

# Environment variables
ENV TEST_NAME=""
ENV SAMOYED_TEST_CONTAINER=1

# Default: run specific test passed via environment variable
CMD if [ -n "$TEST_NAME" ]; then \
        exec /tests/integration/"$TEST_NAME"; \
    else \
        echo "ERROR: TEST_NAME environment variable not set"; \
        echo "Usage: docker run -e TEST_NAME=01_default.sh samoyed-test"; \
        exit 1; \
    fi
