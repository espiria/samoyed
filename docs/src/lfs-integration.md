# Git LFS Integration

Samoyed provides first-class support for Git Large File Storage (LFS), automatically integrating LFS commands into your hooks when needed.

## Overview

Git LFS is a Git extension for versioning large files. It replaces large files with text pointers inside Git, while storing the file contents on a remote server.

Samoyed detects when your repository uses Git LFS and can automatically add the necessary LFS commands to your hooks, ensuring LFS operations run at the right time.

## Automatic Detection

By default, Samoyed auto-detects Git LFS:

```bash
samoyed init
```

Samoyed checks:
1. Is `git-lfs` installed? (`git lfs version`)
2. Is LFS configured in this repo? (`git config filter.lfs.process`)

If both are true, LFS integration is enabled automatically.

###Manual Control

Override auto-detection with flags:

#### Force Enable LFS

```bash
samoyed init --with-lfs
```

Use this when:
- You're about to set up LFS
- Auto-detection failed but you have LFS
- You want LFS integration regardless of current state

#### Force Disable LFS

```bash
samoyed init --no-lfs
```

Use this when:
- You don't use LFS
- You want faster initialization
- You have LFS but don't want Samoyed to manage it

## Managing LFS

After initialization, you can toggle LFS integration:

### Check Status

```bash
samoyed lfs status
```

Example output:
```
Git LFS installation: ✓
Repository LFS config: ✓ Configured
Samoyed hooks initialized: ✓ in .samoyed/_
LFS integration: Enabled
```

### Enable LFS

```bash
samoyed lfs enable
```

Adds LFS commands to existing hooks. Safe to run multiple times.

### Disable LFS

```bash
samoyed lfs disable
```

Removes LFS commands from hooks while preserving other hook logic.

## How It Works

When LFS integration is enabled, Samoyed adds LFS commands to specific hooks:

### pre-push Hook

```sh
#!/usr/bin/env sh
# SAMOYED_LFS_BEGIN
if command -v git-lfs >/dev/null 2>&1; then
    hook_name="$(basename "$0")"
    case "$hook_name" in
        pre-push)
            git lfs pre-push "$@" || exit $?
            ;;
    esac
fi
# SAMOYED_LFS_END

# Your custom hook logic runs after
. "$(dirname "$0")/samoyed"
```

### post-checkout, post-commit, post-merge Hooks

```sh
#!/usr/bin/env sh
# SAMOYED_LFS_BEGIN
if command -v git-lfs >/dev/null 2>&1; then
    hook_name="$(basename "$0")"
    case "$hook_name" in
        post-checkout|post-commit|post-merge)
            git lfs post-checkout "$@"
            ;;
    esac
fi
# SAMOYED_LFS_END

# Your custom hook logic
. "$(dirname "$0")/samoyed"
```

## Execution Order

LFS commands run **before** your custom hooks:

1. LFS commands (if enabled)
2. hooks.d/ scripts (if using [hook composition](./hook-composition.md))
3. Your custom hooks in `.samoyed/`

This ensures LFS files are available when your hooks run.

## Example Workflow

### Setting Up a New Repository with LFS

```bash
# Initialize Git and Samoyed
git init
samoyed init --with-lfs

# Set up LFS for large files
git lfs install
git lfs track "*.psd"
git lfs track "*.zip"

# Create a custom pre-push hook
cat > .samoyed/pre-push <<'EOF'
#!/usr/bin/env sh
echo "Running custom checks..."
cargo test
EOF
chmod +x .samoyed/pre-push

# When you push, LFS runs first, then your tests
git add .
git commit -m "add large files"
git push  # LFS uploads files, then tests run
```

### Adding LFS to Existing Hooks

```bash
# You already have Samoyed set up
cd existing-project

# Enable LFS integration
samoyed lfs enable

# Verify
samoyed lfs status

# Your existing hooks still work!
git commit -m "test"
```

### Removing LFS Integration

```bash
# Remove LFS from hooks
samoyed lfs disable

# Verify
samoyed lfs status
# Shows: LFS integration: Disabled

# Your other hooks still work
```

## Compatibility

### Works With
- Git LFS 2.0+
- All platforms (Linux, macOS, Windows)
- [Hook composition](./hook-composition.md) mode
- Custom hook scripts

### Doesn't Interfere With
- Manual `git lfs` commands
- LFS configuration in `.lfsconfig`
- LFS attributes in `.gitattributes`
- Other LFS tools

## Troubleshooting

### "git-lfs not found" Error

Install Git LFS:
```bash
# macOS
brew install git-lfs

# Ubuntu/Debian
apt-get install git-lfs

# Initialize
git lfs install
```

### LFS Commands Not Running

Check if LFS integration is enabled:
```bash
samoyed lfs status
```

If disabled, enable it:
```bash
samoyed lfs enable
```

### LFS Slowing Down Commits

LFS operations in `post-checkout`, `post-commit`, and `post-merge` are non-blocking (don't fail the operation). Only `pre-push` can fail and prevent a push.

To completely disable:
```bash
samoyed lfs disable
```

### Existing LFS Hooks Conflict

If you have existing LFS hooks in `.git/hooks/`, Samoyed will:
1. Warn you about them
2. Suggest using `--hooks-d` to import them

See [Hook Composition](./hook-composition.md) for details.

## Best Practices

1. **Enable LFS early**: Run `samoyed init --with-lfs` when setting up a new repository
2. **Check status first**: Run `samoyed lfs status` to see current state
3. **Use auto-detection**: Let Samoyed detect LFS automatically in most cases
4. **Combine with hooks.d**: Use [hook composition](./hook-composition.md) for complex workflows
5. **Test thoroughly**: Push to a test branch first when adding LFS to existing repos

## Next Steps

- [Hook Composition](./hook-composition.md): Chain multiple hooks together
- [Combined Features](./combined-features.md): Use LFS with hooks.d
- [Troubleshooting](./troubleshooting.md): Solve common issues
