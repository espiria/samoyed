#!/usr/bin/env sh
# Test: samoyed lfs subcommand (enable, disable, status)

integration_script_dir="$(cd "$(dirname "$0")" && pwd)"
integration_repo_root="$(cd "$integration_script_dir/../.." && pwd)"
cd "$integration_repo_root"
. "$integration_repo_root/tests/integration/functions.sh"

parse_common_args "$@"
build_samoyed
setup

echo "Test: samoyed lfs subcommand"

# Test 1: Status before initialization
echo "  1. Testing 'samoyed lfs status' before init..."
output=$("$SAMOYED_BIN" lfs status 2>&1)

# Check if git-lfs is available - if not, skip some tests
if echo "$output" | grep -q "Install git-lfs"; then
    echo "  ⚠ git-lfs not installed - skipping most lfs subcommand tests"
    cleanup
    echo "✓ All lfs subcommand tests passed (skipped - git-lfs not available)"
    exit 0
fi

if ! echo "$output" | grep -q "Not initialized"; then
    error "Expected 'Not initialized' message before init"
fi
ok "Status reports not initialized correctly"

# Test 2: Initialize without LFS
echo "  2. Initializing without LFS..."
init_samoyed --no-lfs

# Test 3: Status shows LFS disabled
echo "  3. Testing status shows LFS disabled..."
output=$("$SAMOYED_BIN" lfs status 2>&1)
if ! echo "$output" | grep -q "Disabled"; then
    error "Expected LFS to be disabled: $output"
fi
ok "Status correctly shows LFS disabled"

# Test 4: Enable LFS
echo "  4. Testing 'samoyed lfs enable'..."

# Skip if git-lfs not installed
if ! command -v git-lfs >/dev/null 2>&1; then
    echo "  ⚠ Skipping lfs enable test (git-lfs not installed)"
else
    "$SAMOYED_BIN" lfs enable

    # Verify hooks now have LFS integration
    pre_push_hook="..samoyed/..e-push"
    if ! grep -q "SAMOYED_LFS_BEGIN" "$pre_push_hook"; then
        error "LFS not enabled in hooks after 'lfs enable'"
    fi

    ok "LFS enabled successfully"

    # Test 5: Status shows LFS enabled
    echo "  5. Testing status shows LFS enabled..."
    output=$("$SAMOYED_BIN" lfs status 2>&1)
    if ! echo "$output" | grep -q "Enabled"; then
        error "Expected LFS to be enabled: $output"
    fi
    ok "Status correctly shows LFS enabled"

    # Test 6: Disable LFS
    echo "  6. Testing 'samoyed lfs disable'..."
    "$SAMOYED_BIN" lfs disable

    # Verify hooks no longer have LFS integration
    if grep -q "SAMOYED_LFS_BEGIN" "$pre_push_hook"; then
        error "LFS still present in hooks after 'lfs disable'"
    fi

    ok "LFS disabled successfully"

    # Test 7: Status shows LFS disabled again
    echo "  7. Testing status shows LFS disabled after disable..."
    output=$("$SAMOYED_BIN" lfs status 2>&1)
    if ! echo "$output" | grep -q "Disabled"; then
        error "Expected LFS to be disabled after disable: $output"
    fi
    ok "Status correctly shows LFS disabled after toggling"
fi

cleanup
setup

# Test 8: Error handling - enable before init
echo "  8. Testing error when enabling before init..."
output=$("$SAMOYED_BIN" lfs enable 2>&1 || true)
if ! echo "$output" | grep -q "not initialized"; then
    error "Expected error about not initialized: $output"
fi
ok "Proper error when not initialized"

cleanup

echo "✓ All lfs subcommand tests passed"
