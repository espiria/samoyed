# Quick Start

Get started with Samoyed in just a few minutes. This guide walks you through setting up your first Git hook.

## Prerequisites

- Git repository (or create a new one)
- Samoyed [installed](./installation.md)

## Step 1: Initialize Samoyed

Navigate to your Git repository and run:

```bash
cd your-project
samoyed init
```

This creates:
- `.samoyed/` - directory for your hook scripts
- `.samoyed/_/` - directory with generated hook wrappers
- `.samoyed/pre-commit` - sample pre-commit hook

Samoyed automatically configures Git to use these hooks:
```bash
git config core.hooksPath .samoyed/_
```

## Step 2: Create Your First Hook

Let's create a simple pre-commit hook that checks for TODO comments:

```bash
cat > .samoyed/pre-commit <<'EOF'
#!/usr/bin/env sh

# Check for TODO comments
if git diff --cached | grep -E '^\+.*TODO'; then
    echo "❌ Error: Found TODO comments in staged changes"
    echo "Remove or address them before committing"
    exit 1
fi

echo "✓ No TODO comments found"
EOF

chmod +x .samoyed/pre-commit
```

## Step 3: Test It

Try to commit a file with a TODO:

```bash
echo "// TODO: fix this" > test.txt
git add test.txt
git commit -m "test commit"
```

The hook will prevent the commit:
```
❌ Error: Found TODO comments in staged changes
Remove or address them before committing
```

Remove the TODO and try again:
```bash
echo "// Fixed!" > test.txt
git add test.txt
git commit -m "test commit"
```

Success! The commit goes through.

## Step 4: Add More Hooks

Create as many hooks as you need. Common examples:

### Pre-commit: Run Tests

```bash
cat > .samoyed/pre-commit <<'EOF'
#!/usr/bin/env sh
cargo test --quiet
EOF
chmod +x .samoyed/pre-commit
```

### Commit-msg: Validate Format

```bash
cat > .samoyed/commit-msg <<'EOF'
#!/usr/bin/env sh
commit_msg=$(cat "$1")

if ! echo "$commit_msg" | grep -qE '^(feat|fix|docs|chore|test|refactor):'; then
    echo "❌ Commit message must start with a type: feat, fix, docs, chore, test, refactor"
    echo "Example: feat: add new feature"
    exit 1
fi
EOF
chmod +x .samoyed/commit-msg
```

### Pre-push: Run CI Locally

```bash
cat > .samoyed/pre-push <<'EOF'
#!/usr/bin/env sh
echo "Running tests before push..."
cargo test
cargo clippy -- -D warnings
EOF
chmod +x .samoyed/pre-push
```

## Common Commands

```bash
# Initialize hooks
samoyed init

# Initialize with custom directory
samoyed init my-hooks

# Check Git LFS status
samoyed lfs status

# Enable Git LFS integration
samoyed lfs enable

# Bypass hooks temporarily
SAMOYED=0 git commit -m "emergency fix"

# Debug hook execution
SAMOYED=2 git commit -m "test"
```

## Next Steps

- [Basic Usage](./basic-usage.md): Learn all the features
- [Git LFS Integration](./lfs-integration.md): Work with large files
- [Hook Composition](./hook-composition.md): Chain multiple hooks
- [Common Use Cases](./use-cases.md): Real-world examples

## Troubleshooting

### Hooks not running?

Check that Git is configured correctly:
```bash
git config core.hooksPath
# Should show: .samoyed/_
```

### Need to skip hooks once?

Use the bypass mode:
```bash
SAMOYED=0 git commit -m "skip hooks"
```

### Want to see what's happening?

Enable debug mode:
```bash
SAMOYED=2 git commit -m "debug"
```
