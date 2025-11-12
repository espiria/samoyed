#!/usr/bin/env bash
# Validation script for containerized test setup
# This script verifies that all components are in place

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "========================================"
echo "Validating Containerized Test Setup"
echo "========================================"
echo ""

errors=0

# Check Dockerfile
echo "Checking Dockerfile..."
if [ -f "$REPO_ROOT/Dockerfile" ]; then
    echo "  ✓ Dockerfile exists"

    # Validate it has multi-stage build
    if grep -q "FROM.*AS builder" "$REPO_ROOT/Dockerfile" && \
       grep -q "FROM.*AS test-runner" "$REPO_ROOT/Dockerfile"; then
        echo "  ✓ Multi-stage build configured"
    else
        echo "  ✗ Multi-stage build not properly configured"
        ((errors++))
    fi

    # Check if samoyed binary is copied
    if grep -q "COPY --from=builder.*samoyed" "$REPO_ROOT/Dockerfile"; then
        echo "  ✓ Binary copy configured"
    else
        echo "  ✗ Binary copy not configured"
        ((errors++))
    fi
else
    echo "  ✗ Dockerfile not found"
    ((errors++))
fi

echo ""

# Check .dockerignore
echo "Checking .dockerignore..."
if [ -f "$REPO_ROOT/.dockerignore" ]; then
    echo "  ✓ .dockerignore exists"
else
    echo "  ⚠ .dockerignore not found (optional but recommended)"
fi

echo ""

# Check functions.sh modifications
echo "Checking functions.sh..."
if [ -f "$SCRIPT_DIR/functions.sh" ]; then
    echo "  ✓ functions.sh exists"

    # Check for is_containerized function
    if grep -q "^is_containerized()" "$SCRIPT_DIR/functions.sh"; then
        echo "  ✓ is_containerized() function added"
    else
        echo "  ✗ is_containerized() function not found"
        ((errors++))
    fi

    # Check build_samoyed modification
    if grep -q "if is_containerized" "$SCRIPT_DIR/functions.sh"; then
        echo "  ✓ build_samoyed() modified for containers"
    else
        echo "  ✗ build_samoyed() not modified for containers"
        ((errors++))
    fi
else
    echo "  ✗ functions.sh not found"
    ((errors++))
fi

echo ""

# Check parallel runner script
echo "Checking parallel runner..."
if [ -f "$SCRIPT_DIR/run-parallel-docker.sh" ]; then
    echo "  ✓ run-parallel-docker.sh exists"

    if [ -x "$SCRIPT_DIR/run-parallel-docker.sh" ]; then
        echo "  ✓ Script is executable"
    else
        echo "  ⚠ Script is not executable (run: chmod +x)"
    fi

    # Check for proper error handling
    if grep -q "set -euo pipefail" "$SCRIPT_DIR/run-parallel-docker.sh"; then
        echo "  ✓ Error handling configured"
    else
        echo "  ✗ Error handling not configured"
        ((errors++))
    fi
else
    echo "  ✗ run-parallel-docker.sh not found"
    ((errors++))
fi

echo ""

# Check Docker Compose file
echo "Checking Docker Compose..."
if [ -f "$REPO_ROOT/docker-compose.test.yml" ]; then
    echo "  ✓ docker-compose.test.yml exists"

    # Count test services
    service_count=$(grep -c "test-[0-9]*-" "$REPO_ROOT/docker-compose.test.yml" || true)
    echo "  ✓ Found $service_count test services defined"
else
    echo "  ✗ docker-compose.test.yml not found"
    ((errors++))
fi

echo ""

# Check Makefile
echo "Checking Makefile..."
if [ -f "$REPO_ROOT/Makefile" ]; then
    echo "  ✓ Makefile exists"

    if grep -q "test-docker-parallel" "$REPO_ROOT/Makefile"; then
        echo "  ✓ test-docker-parallel target exists"
    else
        echo "  ⚠ test-docker-parallel target not found"
    fi
else
    echo "  ⚠ Makefile not found (optional)"
fi

echo ""

# Test container detection
echo "Testing container detection..."
cd "$REPO_ROOT"
detection_result=$(bash -c '
    source tests/integration/functions.sh
    if is_containerized; then
        echo "container"
    else
        echo "host"
    fi
')
echo "  Detected environment: $detection_result"

echo ""

# Summary
echo "========================================"
echo "Validation Summary"
echo "========================================"
if [ $errors -eq 0 ]; then
    echo "✓ All checks passed!"
    echo ""
    echo "Next steps:"
    echo "  1. Build the image: docker build -t samoyed-test ."
    echo "  2. Run parallel tests: make test-docker-parallel"
    echo "  3. Or use: bash tests/integration/run-parallel-docker.sh"
    exit 0
else
    echo "✗ Found $errors error(s)"
    echo ""
    echo "Please fix the errors above before using containerized tests."
    exit 1
fi
