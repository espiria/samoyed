#!/usr/bin/env sh
# Test: Existing hook detection and import

integration_script_dir="$(cd "$(dirname "$0")" && pwd)"
integration_repo_root="$(cd "$integration_script_dir/../.." && pwd)"
cd "$integration_repo_root"
. "$integration_repo_root/tests/integration/functions.sh"

parse_common_args "$@"
build_samoyed
setup

echo "Test: Existing hook detection and import"

# Test 1: Create existing hooks in .git/hooks
echo "  1. Setting up existing hooks..."

# Create some existing hooks
cat > ".git/hooks/pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "Existing pre-commit hook"
exit 0
EOF
chmod +x ".git/hooks/pre-commit"

cat > ".git/hooks/pre-push" <<'EOF'
#!/usr/bin/env sh
echo "Existing pre-push hook"
exit 0
EOF
chmod +x ".git/hooks/pre-push"

ok "Created existing hooks in .git/hooks"

# Test 2: Initialize without --hooks-d should warn
echo "  2. Testing warning without --hooks-d..."
output=$("$SAMOYED_BIN" init 2>&1)

if ! echo "$output" | grep -q "Warning.*Existing.*hooks.*detected"; then
    error "Expected warning about existing hooks"
fi

if ! echo "$output" | grep -q "pre-commit"; then
    error "Expected pre-commit to be listed"
fi

if ! echo "$output" | grep -q "pre-push"; then
    error "Expected pre-push to be listed"
fi

if ! echo "$output" | grep -q "Use --hooks-d to import"; then
    error "Expected suggestion to use --hooks-d"
fi

ok "Warning displayed about existing hooks"

# Test 3: Existing hooks become inactive without import
echo "  3. Verifying existing hooks are inactive..."

# Create a test commit - existing hooks should NOT run
# Already in test directory
echo "test" > testfile.txt
git add testfile.txt

# Capture commit output
commit_output=$(git commit -m "test" 2>&1 || true)

# Old hooks should not run
if echo "$commit_output" | grep -q "Existing pre-commit hook"; then
    error "Old hook still running after samoyed init"
fi

ok "Existing hooks become inactive after init"

# Clean up for next test
cleanup
setup

# Test 4: Initialize with --hooks-d should import hooks
echo "  4. Testing import with --hooks-d..."

# Create existing hooks again
cat > ".git/hooks/pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "IMPORTED_HOOK_RAN" >> imported_hook_test.txt
exit 0
EOF
chmod +x ".git/hooks/pre-commit"

cat > ".git/hooks/commit-msg" <<'EOF'
#!/usr/bin/env sh
echo "commit-msg hook"
exit 0
EOF
chmod +x ".git/hooks/commit-msg"

# Initialize with --hooks-d
output=$("$SAMOYED_BIN" init --hooks-d 2>&1)

if ! echo "$output" | grep -q "Importing existing hooks"; then
    error "Expected message about importing hooks"
fi

# Verify hooks were imported
if [ ! -f ".samoyed/hooks.d/50-imported.pre-commit" ]; then
    error "pre-commit hook not imported"
fi

if [ ! -f ".samoyed/hooks.d/50-imported.commit-msg" ]; then
    error "commit-msg hook not imported"
fi

ok "Existing hooks imported to hooks.d/"

# Test 5: Verify imported hooks have correct permissions
echo "  5. Testing imported hook permissions..."

if [ ! -x ".samoyed/hooks.d/50-imported.pre-commit" ]; then
    error "Imported hook is not executable"
fi

ok "Imported hooks are executable"

# Test 6: Verify imported hooks actually run
echo "  6. Testing imported hooks execute..."

# Already in test directory
echo "test" > testfile.txt
git add testfile.txt
git commit -m "test" >/dev/null 2>&1 || error "Commit failed"

if [ ! -f "imported_hook_test.txt" ]; then
    error "Imported hook did not run"
fi

if ! grep -q "IMPORTED_HOOK_RAN" "imported_hook_test.txt"; then
    error "Imported hook did not execute correctly"
fi

ok "Imported hooks execute during git operations"

# Test 7: Test with custom hooks path (not .git/hooks)
cleanup
setup

echo "  7. Testing with custom hooks path..."

# Set custom hooks path
git config core.hooksPath ".custom-hooks"
mkdir -p ".custom-hooks"

cat > ".custom-hooks/pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "Custom path hook"
exit 0
EOF
chmod +x ".custom-hooks/pre-commit"

# Initialize with --hooks-d
output=$("$SAMOYED_BIN" init --hooks-d 2>&1)

if ! echo "$output" | grep -q "Existing.*hooks.*detected"; then
    error "Did not detect hooks in custom path"
fi

if ! echo "$output" | grep -q ".custom-hooks"; then
    error "Custom hooks path not shown in warning"
fi

# Verify hook was imported
if [ ! -f ".samoyed/hooks.d/50-imported.pre-commit" ]; then
    error "Hook from custom path not imported"
fi

ok "Hooks from custom path detected and imported"

# Test 8: Test with absolute hooks path
cleanup
setup

echo "  8. Testing with absolute hooks path..."

# Create hooks directory outside repo
abs_hooks_dir="$WORKDIR/absolute-hooks"
mkdir -p "$abs_hooks_dir"

cat > "$abs_hooks_dir/pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "Absolute path hook"
exit 0
EOF
chmod +x "$abs_hooks_dir/pre-commit"

# Set absolute hooks path
# Already in test directory
git config core.hooksPath "$abs_hooks_dir"

# Initialize with --hooks-d
output=$("$SAMOYED_BIN" init --hooks-d 2>&1)

if ! echo "$output" | grep -q "Existing.*hooks.*detected"; then
    error "Did not detect hooks in absolute path"
fi

# Verify hook was imported
if [ ! -f ".samoyed/hooks.d/50-imported.pre-commit" ]; then
    error "Hook from absolute path not imported"
fi

ok "Hooks from absolute path detected and imported"

cleanup

echo "✓ All existing hook detection and import tests passed"
