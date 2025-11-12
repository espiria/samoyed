#!/usr/bin/env sh
# Test: Combined features (LFS + hooks.d together)

integration_script_dir="$(cd "$(dirname "$0")" && pwd)"
integration_repo_root="$(cd "$integration_script_dir/../.." && pwd)"
cd "$integration_repo_root"
. "$integration_repo_root/tests/integration/functions.sh"

parse_common_args "$@"
build_samoyed
setup

echo "Test: Combined features (LFS + hooks.d)"

# Test 1: Initialize with both --with-lfs and --hooks-d
echo "  1. Testing --with-lfs --hooks-d together..."
init_samoyed --with-lfs --hooks-d

# Verify hooks.d directory exists
if [ ! -d "..samoyed/hooks.d" ]; then
    error "hooks.d directory not created"
fi

ok "Both flags accepted together"

# Test 2: Verify hooks have BOTH LFS and hooks.d code
echo "  2. Verifying combined template..."

pre_push_hook="..samoyed/..e-push"
content=$(cat "$pre_push_hook")

if ! echo "$content" | grep -q "SAMOYED_LFS_BEGIN"; then
    error "LFS integration not found in combined mode"
fi

if ! echo "$content" | grep -q "SAMOYED_HOOKS_D"; then
    error "hooks.d composition not found in combined mode"
fi

# Verify correct order: LFS first, then hooks.d, then user hook
lfs_line=$(grep -n "SAMOYED_LFS_BEGIN" "$pre_push_hook" | cut -d: -f1)
hooks_d_line=$(grep -n "SAMOYED_HOOKS_D" "$pre_push_hook" | cut -d: -f1)
source_line=$(grep -n '. "$(dirname "$0")/samoyed"' "$pre_push_hook" | tail -1 | cut -d: -f1)

if [ "$lfs_line" -ge "$hooks_d_line" ]; then
    error "LFS should come before hooks.d in template"
fi

if [ "$hooks_d_line" -ge "$source_line" ]; then
    error "hooks.d should come before user hook sourcing"
fi

ok "Combined template has correct structure and order"

# Test 3: Test execution order (LFS -> hooks.d -> user hook)
echo "  3. Testing execution order in combined mode..."

# Create output file
output_file=".execution_order.txt"

# Note: We can't easily test LFS commands without actual LFS setup,
# but we can test hooks.d and user hook order

# Create a hook in hooks.d
cat > "..samoyed/hooks.d/50-test.pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "hooks.d-script" >> execution_order.txt
EOF
chmod +x "..samoyed/hooks.d/50-test.pre-commit"

# Create user hook
cat > "..samoyed/pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "user-hook" >> execution_order.txt
EOF
chmod +x "..samoyed/pre-commit"

# Trigger hook
# Already in test directory
echo "test" > testfile.txt
git add testfile.txt
git commit -m "test" >/dev/null 2>&1 || true

# Verify order
if [ ! -f "$output_file" ]; then
    error "Execution order file not created"
fi

order=$(cat "$output_file")
expected="hooks.d-script
user-hook"

if [ "$order" != "$expected" ]; then
    error "Execution order incorrect in combined mode"
fi

ok "Execution order correct in combined mode"

cleanup
setup

# Test 4: Enable/disable LFS preserves hooks.d mode
echo "  4. Testing LFS toggle preserves hooks.d mode..."

# Initialize with hooks.d only
init_samoyed --hooks-d

pre_push_hook="..samoyed/..e-push"

# Verify hooks.d but no LFS
if ! grep -q "SAMOYED_HOOKS_D" "$pre_push_hook"; then
    error "hooks.d not enabled initially"
fi

if grep -q "SAMOYED_LFS_BEGIN" "$pre_push_hook"; then
    error "LFS should not be enabled initially"
fi

# Skip if git-lfs not available
if ! command -v git-lfs >/dev/null 2>&1; then
    echo "  ⚠ Skipping LFS toggle test (git-lfs not installed)"
else
    # Enable LFS
    "$SAMOYED_BIN" lfs enable

    # Verify both LFS and hooks.d are present
    if ! grep -q "SAMOYED_LFS_BEGIN" "$pre_push_hook"; then
        error "LFS not enabled after lfs enable"
    fi

    if ! grep -q "SAMOYED_HOOKS_D" "$pre_push_hook"; then
        error "hooks.d mode lost after lfs enable"
    fi

    ok "LFS enable preserves hooks.d mode"

    # Disable LFS
    "$SAMOYED_BIN" lfs disable

    # Verify hooks.d still present, LFS removed
    if grep -q "SAMOYED_LFS_BEGIN" "$pre_push_hook"; then
        error "LFS still present after lfs disable"
    fi

    if ! grep -q "SAMOYED_HOOKS_D" "$pre_push_hook"; then
        error "hooks.d mode lost after lfs disable"
    fi

    ok "LFS disable preserves hooks.d mode"
fi

cleanup
setup

# Test 5: Import existing hooks with LFS enabled
echo "  5. Testing hook import with LFS..."

# Create existing hook
cat > "..git/hooks/pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "EXISTING_HOOK" >> existing_test.txt
exit 0
EOF
chmod +x "..git/hooks/pre-commit"

# Initialize with both flags
init_samoyed --with-lfs --hooks-d

# Verify imported hook exists
if [ ! -f "..samoyed/hooks.d/50-imported.pre-commit" ]; then
    error "Existing hook not imported with combined flags"
fi

# Test execution
# Already in test directory
echo "test" > testfile.txt
git add testfile.txt
git commit -m "test" >/dev/null 2>&1 || error "Commit failed"

if [ ! -f ".existing_test.txt" ]; then
    error "Imported hook did not execute in combined mode"
fi

ok "Existing hooks imported and execute with combined flags"

# Test 6: Status command shows both features
echo "  6. Testing status shows both features..."

output=$("$SAMOYED_BIN" lfs status 2>&1)

if ! echo "$output" | grep -q "Hook composition mode.*Enabled"; then
    error "Status should show hooks.d enabled"
fi

ok "Status correctly shows both features"

cleanup

echo "✓ All combined feature tests passed"
