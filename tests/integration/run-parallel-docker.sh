#!/usr/bin/env bash
# Parallel integration test runner for Samoyed using Docker
# This script builds the test image once and runs all tests in parallel

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGE_NAME="${SAMOYED_TEST_IMAGE:-samoyed-test:latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Find all test scripts
TEST_SCRIPTS=(
    01_default.sh
    02_custom_dir.sh
    03_from_subdir.sh
    04_not_git_dir.sh
    05_git_not_found.sh
    06_command_not_found.sh
    07_strict_mode.sh
    08_samoyed_0.sh
    09_init.sh
    10_time.sh
    11_lfs_flags.sh
    12_lfs_subcommand.sh
    13_hooks_d.sh
    14_existing_hooks.sh
    15_combined_features.sh
)

echo ""
echo "========================================"
echo "Samoyed Integration Tests (Parallel)"
echo "========================================"
echo ""

# Build container once
echo -e "${BLUE}Building test container image...${NC}"
cd "$REPO_ROOT"

if docker build -t "$IMAGE_NAME" -f Dockerfile . 2>&1 | \
    grep -E "(^Step |^Successfully |ERROR|error:)"; then
    echo -e "${GREEN}✓ Container image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build container image${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo "Running ${#TEST_SCRIPTS[@]} tests in parallel..."
echo "========================================"
echo ""

# Track results
declare -A test_results
declare -A test_pids
declare -A test_start_times
start_time=$(date +%s)

# Create temporary directory for test outputs
TEST_OUTPUT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/samoyed-test-output.XXXXXX")
trap "rm -rf '$TEST_OUTPUT_DIR'" EXIT

# Launch all tests in parallel
for test_script in "${TEST_SCRIPTS[@]}"; do
    test_name="${test_script%.sh}"
    output_file="$TEST_OUTPUT_DIR/$test_name.log"
    result_file="$TEST_OUTPUT_DIR/$test_name.result"

    # Record start time
    test_start_times["$test_name"]=$(date +%s)

    # Run test in isolated container
    (
        # Run container and capture exit code
        docker run --rm \
            --name "samoyed-test-$test_name-$$" \
            -e "TEST_NAME=$test_script" \
            "$IMAGE_NAME" \
        > "$output_file" 2>&1

        exit_code=$?

        # Write result
        echo "$exit_code" > "$result_file"
    ) &

    test_pids["$test_name"]=$!
    echo -e "${BLUE}→${NC} Started: $test_name (PID: ${test_pids[$test_name]})"
done

echo ""
echo -e "${YELLOW}Waiting for tests to complete...${NC}"
echo ""

# Wait for all tests and collect results
passed=0
failed=0
failed_tests=()

for test_name in "${!test_pids[@]}"; do
    pid=${test_pids[$test_name]}
    output_file="$TEST_OUTPUT_DIR/$test_name.log"
    result_file="$TEST_OUTPUT_DIR/$test_name.result"

    # Wait for specific test
    wait "$pid" 2>/dev/null || true

    # Calculate duration
    end_time=$(date +%s)
    duration=$((end_time - test_start_times[$test_name]))

    # Read result
    if [ -f "$result_file" ]; then
        exit_code=$(cat "$result_file")
    else
        exit_code=1
    fi

    # Store result
    test_results["$test_name"]=$exit_code

    # Display result with duration
    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name (${duration}s)"
        ((passed++))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name (${duration}s, exit code: $exit_code)"
        ((failed++))
        failed_tests+=("$test_name")
    fi
done

# Show logs for failed tests
if [ $failed -gt 0 ]; then
    echo ""
    echo "========================================"
    echo -e "${RED}Failed Test Logs${NC}"
    echo "========================================"
    for test_name in "${failed_tests[@]}"; do
        output_file="$TEST_OUTPUT_DIR/$test_name.log"
        echo ""
        echo -e "${YELLOW}--- $test_name ---${NC}"
        if [ -f "$output_file" ]; then
            # Show last 50 lines of failed test
            tail -n 50 "$output_file" | sed 's/^/  /'
        else
            echo "  (no output captured)"
        fi
    done
fi

end_time=$(date +%s)
total_duration=$((end_time - start_time))

# Summary
echo ""
echo "========================================"
echo "TEST RESULTS"
echo "========================================"
echo "Total:    ${#TEST_SCRIPTS[@]} tests"
echo -e "Passed:   ${GREEN}$passed${NC}"
echo -e "Failed:   ${RED}$failed${NC}"
echo "Duration: ${total_duration}s"

if [ $failed -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed tests:${NC}"
    for test in "${failed_tests[@]}"; do
        echo "  - $test"
    done
    echo ""
    echo -e "${YELLOW}Tip: Re-run a specific test with:${NC}"
    echo "  docker run --rm -e TEST_NAME=<test>.sh $IMAGE_NAME"
    echo ""
    exit 1
else
    echo ""
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    exit 0
fi
