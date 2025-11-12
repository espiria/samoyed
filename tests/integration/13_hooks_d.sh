#!/usr/bin/env sh
# Test: Hook composition mode (--hooks-d flag and hooks.d directory)

integration_script_dir="$(cd "$(dirname "$0")" && pwd)"
integration_repo_root="$(cd "$integration_script_dir/../.." && pwd)"
cd "$integration_repo_root"
. "$integration_repo_root/tests/integration/functions.sh"

parse_common_args "$@"
build_samoyed
setup

echo "Test: Hook composition mode"

# Test 1: Initialize with --hooks-d flag
echo "  1. Testing --hooks-d flag..."
init_samoyed --hooks-d

# Verify hooks.d directory exists
if [ ! -d ".samoyed/hooks.d" ]; then
    error "hooks.d directory not created"
fi

ok "hooks.d directory created with --hooks-d flag"

# Test 2: Verify hook scripts contain SAMOYED_HOOKS_D marker
echo "  2. Verifying hook composition code in hooks..."
pre_commit_hook=".samoyed/_/pre-commit"
if ! grep -q "SAMOYED_HOOKS_D" "$pre_commit_hook"; then
    error "SAMOYED_HOOKS_D marker not found in hooks"
fi

if ! grep -q 'hooks_d_dir="$(dirname "$0")/../hooks.d"' "$pre_commit_hook"; then
    error "hooks.d directory reference not found in hooks"
fi

ok "Hook scripts contain composition code"

# Test 3: Create multiple hooks in hooks.d and test execution order
echo "  3. Testing hook execution order..."

# Create output file to track execution order
output_file="hook_execution_order.txt"

# Create first hook (should run first - lexicographic order)
cat > ".samoyed/hooks.d/10-first.pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "10-first" >> hook_execution_order.txt
EOF
chmod +x ".samoyed/hooks.d/10-first.pre-commit"

# Create second hook (should run second)
cat > ".samoyed/hooks.d/20-second.pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "20-second" >> hook_execution_order.txt
EOF
chmod +x ".samoyed/hooks.d/20-second.pre-commit"

# Create third hook (should run third)
cat > ".samoyed/hooks.d/30-third.pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "30-third" >> hook_execution_order.txt
EOF
chmod +x ".samoyed/hooks.d/30-third.pre-commit"

# Create user hook in .samoyed/ (should run after hooks.d)
cat > ".samoyed/pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "user-hook" >> hook_execution_order.txt
EOF
chmod +x ".samoyed/pre-commit"

# Create a test commit to trigger pre-commit hook
# Already in test directory
echo "test" > testfile.txt
git add testfile.txt
git commit -m "test commit" >/dev/null 2>&1 || true

# Verify execution order
if [ ! -f "$output_file" ]; then
    error "Hook execution order file not created"
fi

# Check the order
order=$(cat "$output_file")
expected="10-first
20-second
30-third
user-hook"

if [ "$order" != "$expected" ]; then
    error "Execution order incorrect. Expected:
$expected
Got:
$order"
fi

ok "Hooks execute in correct order (lexicographic + user hook last)"

# Test 4: Hook failure propagation
echo "  4. Testing hook failure propagation..."

# Already in test directory
git reset --hard HEAD~1 >/dev/null 2>&1 || true
rm -f "$output_file"

# Create a failing hook
cat > ".samoyed/hooks.d/15-fail.pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "15-fail" >> hook_execution_order.txt
exit 1
EOF
chmod +x ".samoyed/hooks.d/15-fail.pre-commit"

# Try to commit - should fail
echo "test2" > testfile2.txt
git add testfile2.txt
if git commit -m "should fail" >/dev/null 2>&1; then
    error "Commit succeeded when hook should have failed"
fi

# Verify hooks stopped after failure (30-third should NOT have run)
if [ ! -f "$output_file" ]; then
    error "No hooks ran before failure"
fi

if grep -q "30-third" "$output_file"; then
    error "Hooks continued after failure"
fi

if ! grep -q "15-fail" "$output_file"; then
    error "Failing hook did not execute"
fi

ok "Hook failure stops execution chain"

# Test 5: Non-executable hooks are skipped
echo "  5. Testing non-executable hooks are skipped..."

# Already in test directory
rm -f "$output_file"
git reset --hard HEAD >/dev/null 2>&1 || true

# Remove the failing hook
rm -f ".samoyed/hooks.d/15-fail.pre-commit"

# Create a non-executable hook
cat > ".samoyed/hooks.d/25-notexec.pre-commit" <<'EOF'
#!/usr/bin/env sh
echo "25-notexec" >> hook_execution_order.txt
EOF
# Don't make it executable

# Commit should succeed and skip non-executable hook
echo "test3" > testfile3.txt
git add testfile3.txt
git commit -m "test commit 2" >/dev/null 2>&1 || error "Commit failed"

# Verify non-executable hook was skipped
if grep -q "25-notexec" "$output_file"; then
    error "Non-executable hook was executed"
fi

# But others should have run
if ! grep -q "10-first" "$output_file"; then
    error "Executable hooks did not run"
fi

ok "Non-executable hooks are skipped"

cleanup

echo "✓ All hooks.d composition tests passed"
