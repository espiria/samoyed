#!/usr/bin/env sh
# Test: Git LFS integration with --with-lfs and --no-lfs flags

integration_script_dir="$(cd "$(dirname "$0")" && pwd)"
integration_repo_root="$(cd "$integration_script_dir/../.." && pwd)"
cd "$integration_repo_root"
. "$integration_repo_root/tests/integration/functions.sh"

parse_common_args "$@"
build_samoyed
setup

echo "Test: Git LFS integration flags"

# Test 1: Force enable LFS with --with-lfs
echo "  1. Testing --with-lfs flag..."
init_samoyed --with-lfs

# Verify LFS markers in hook scripts
pre_push_hook=".samoyed/_/pre-push"
if [ ! -f "$pre_push_hook" ]; then
    error "pre-push hook not created"
fi

if ! grep -q "SAMOYED_LFS_BEGIN" "$pre_push_hook"; then
    error "LFS integration not found in hooks (--with-lfs)"
fi

if ! grep -q "git lfs pre-push" "$pre_push_hook"; then
    error "git lfs pre-push command not found in pre-push hook"
fi

ok "LFS integration enabled with --with-lfs"

# Test 2: Verify post-checkout hook has LFS
post_checkout_hook=".samoyed/_/post-checkout"
if ! grep -q "git lfs post-checkout" "$post_checkout_hook"; then
    error "git lfs post-checkout command not found"
fi

ok "LFS post-checkout hook configured correctly"

cleanup
setup

# Test 3: Force disable LFS with --no-lfs
echo "  2. Testing --no-lfs flag..."
init_samoyed --no-lfs

# Verify NO LFS markers in hook scripts
pre_push_hook=".samoyed/_/pre-push"
if grep -q "SAMOYED_LFS_BEGIN" "$pre_push_hook"; then
    error "LFS integration found when --no-lfs was specified"
fi

if grep -q "git lfs" "$pre_push_hook"; then
    error "git lfs commands found when --no-lfs was specified"
fi

ok "LFS integration disabled with --no-lfs"

cleanup
setup

# Test 4: Auto-detection (no flags)
echo "  3. Testing auto-detection..."
init_samoyed

# Just verify it doesn't crash - actual LFS detection depends on environment
if [ ! -f ".samoyed/_/pre-push" ]; then
    error "Hooks not created with auto-detection"
fi

ok "Auto-detection works without flags"

cleanup

echo "✓ All LFS flag tests passed"
