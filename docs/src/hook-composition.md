# Hook Composition

Hook composition allows you to run multiple hook scripts in sequence using the `hooks.d/` pattern. This is perfect for complex workflows, team environments, or when migrating from other tools.

## Overview

Instead of writing one large hook script, you can split your hooks into multiple smaller scripts that run in sequence. This makes hooks:

- **Modular**: Each script does one thing
- **Maintainable**: Easy to add, remove, or modify individual checks
- **Composable**: Mix hooks from different sources (LFS, imported, custom)
- **Organized**: Clear naming and execution order

## Enabling Hook Composition

### New Initialization

```bash
samoyed init --hooks-d
```

This creates:
- `.samoyed/hooks.d/` - directory for multiple hook scripts
- Modified hooks that scan and run `hooks.d/` scripts

### Existing Setup

If you already have Samoyed initialized:

```bash
# Remove old setup
rm -rf .samoyed
git config --unset core.hooksPath

# Re-initialize with hooks.d
samoyed init --hooks-d
```

## hooks.d Pattern

### Directory Structure

```
.samoyed/
├── hooks.d/
│   ├── 10-format.pre-commit
│   ├── 20-lint.pre-commit
│   ├── 30-test.pre-commit
│   ├── 50-imported.pre-push
│   └── 99-notify.post-commit
├── pre-commit           # Your main hook (runs last)
├── pre-push
└── _/                   # Generated wrappers
    ├── pre-commit
    ├── pre-push
    └── samoyed
```

### Naming Convention

Files in `hooks.d/` must follow this pattern:

```
<priority>-<name>.<hook-type>
```

Examples:
- `10-format.pre-commit` - Runs first in pre-commit
- `20-lint.pre-commit` - Runs second in pre-commit
- `50-imported.pre-push` - Runs during pre-push
- `99-notify.post-commit` - Runs last in post-commit

**Priority determines execution order** (lexicographic sort):
- `10-*` runs before `20-*`
- `20-*` runs before `50-*`
- etc.

## Execution Order

For each Git hook, scripts run in this order:

1. **LFS commands** (if [LFS integration](./lfs-integration.md) enabled)
2. **hooks.d/ scripts** (in lexicographic order)
3. **Main hook** (`.samoyed/<hook-name>`)

### Example Flow

With this setup:
```
.samoyed/hooks.d/10-format.pre-commit
.samoyed/hooks.d/20-test.pre-commit
.samoyed/pre-commit
```

When you run `git commit`:
```
1. Git LFS commands (if enabled)
2. hooks.d/10-format.pre-commit
3. hooks.d/20-test.pre-commit
4. .samoyed/pre-commit
```

## Creating Composed Hooks

### Example 1: Code Quality Pipeline

```bash
# Format check
cat > .samoyed/hooks.d/10-format.pre-commit <<'EOF'
#!/usr/bin/env sh
echo "→ Checking code formatting..."
cargo fmt -- --check || exit 1
echo "✓ Format OK"
EOF
chmod +x .samoyed/hooks.d/10-format.pre-commit

# Lint check
cat > .samoyed/hooks.d/20-lint.pre-commit <<'EOF'
#!/usr/bin/env sh
echo "→ Running linter..."
cargo clippy -- -D warnings || exit 1
echo "✓ Lint OK"
EOF
chmod +x .samoyed/hooks.d/20-lint.pre-commit

# Tests
cat > .samoyed/hooks.d/30-test.pre-commit <<'EOF'
#!/usr/bin/env sh
echo "→ Running tests..."
cargo test --quiet || exit 1
echo "✓ Tests OK"
EOF
chmod +x .samoyed/hooks.d/30-test.pre-commit
```

### Example 2: Multi-Language Project

```bash
# Rust checks
cat > .samoyed/hooks.d/10-rust.pre-commit <<'EOF'
#!/usr/bin/env sh
if git diff --cached --name-only | grep -q '\.rs$'; then
    echo "→ Checking Rust..."
    cargo fmt --check && cargo clippy
fi
EOF
chmod +x .samoyed/hooks.d/10-rust.pre-commit

# JavaScript checks
cat > .samoyed/hooks.d/20-js.pre-commit <<'EOF'
#!/usr/bin/env sh
if git diff --cached --name-only | grep -q '\.js$'; then
    echo "→ Checking JavaScript..."
    npm run lint && npm test
fi
EOF
chmod +x .samoyed/hooks.d/20-js.pre-commit

# Python checks
cat > .samoyed/hooks.d/30-python.pre-commit <<'EOF'
#!/usr/bin/env sh
if git diff --cached --name-only | grep -q '\.py$'; then
    echo "→ Checking Python..."
    black --check . && pylint **/*.py
fi
EOF
chmod +x .samoyed/hooks.d/30-python.pre-commit
```

## Importing Existing Hooks

When you initialize with `--hooks-d`, Samoyed can import existing hooks from other tools.

### Automatic Import

```bash
# Samoyed detects existing hooks
samoyed init --hooks-d
```

Output:
```
Warning: Existing Git hooks detected in .git/hooks
  - pre-commit
  - pre-push

These hooks will become inactive after initialization.
Use --hooks-d to import them to hooks.d/

Importing existing hooks...
  ✓ Imported pre-commit → .samoyed/hooks.d/50-imported.pre-commit
  ✓ Imported pre-push → .samoyed/hooks.d/50-imported.pre-push
```

Imported hooks use priority `50` by default, running after your custom checks but before the main hook.

### Custom Hooks Path

If your repository uses a custom `core.hooksPath`:

```bash
git config core.hooksPath .githooks
```

Samoyed detects and imports from there:

```bash
samoyed init --hooks-d
```

Output:
```
Warning: Existing Git hooks detected in .githooks
  - pre-commit

Importing existing hooks...
  ✓ Imported pre-commit → .samoyed/hooks.d/50-imported.pre-commit
```

## Failure Handling

### Stop on First Failure

By default, if any hook fails, the rest don't run:

```bash
# hooks.d/10-format.pre-commit fails → execution stops
# hooks.d/20-test.pre-commit doesn't run
# .samoyed/pre-commit doesn't run
```

This is the **recommended behavior** for most cases.

### Continue on Failure (Advanced)

If you need a hook to run but not fail the operation:

```bash
cat > .samoyed/hooks.d/10-optional.pre-commit <<'EOF'
#!/usr/bin/env sh
some-command || true  # Always exit 0
EOF
chmod +x .samoyed/hooks.d/10-optional.pre-commit
```

## Best Practices

### Naming

Use descriptive names and priorities:
- `10-format` - Fast checks first
- `20-lint` - Medium checks
- `30-test` - Slower checks last
- `50-imported` - Imported hooks
- `99-notify` - Notifications (always last)

### Priority Ranges

Suggested priority ranges:
- **00-09**: Pre-flight checks (fast, essential)
- **10-29**: Format and lint (fast feedback)
- **30-49**: Tests and builds (slower)
- **50-59**: Imported hooks
- **60-89**: Integration checks
- **90-99**: Notifications and logging

### Permissions

Always make hooks executable:
```bash
chmod +x .samoyed/hooks.d/*.pre-commit
```

Non-executable files are silently skipped.

### Testing

Test individual hooks:
```bash
# Run a specific hook
.samoyed/hooks.d/10-format.pre-commit

# Test the full chain
git commit --allow-empty -m "test"
```

## Real-World Example

A complete pre-commit pipeline:

```bash
# 00-fast: Quick sanity checks
cat > .samoyed/hooks.d/00-fast.pre-commit <<'EOF'
#!/usr/bin/env sh
# Check for merge conflicts
if git diff --cached | grep -E '^(<<<<<<<|=======|>>>>>>>)'; then
    echo "❌ Merge conflict markers found"
    exit 1
fi
EOF

# 10-format: Code formatting
cat > .samoyed/hooks.d/10-format.pre-commit <<'EOF'
#!/usr/bin/env sh
echo "→ Checking format..."
cargo fmt -- --check
EOF

# 20-lint: Linting
cat > .samoyed/hooks.d/20-lint.pre-commit <<'EOF'
#!/usr/bin/env sh
echo "→ Running clippy..."
cargo clippy -- -D warnings
EOF

# 30-test: Unit tests
cat > .samoyed/hooks.d/30-test.pre-commit <<'EOF'
#!/usr/bin/env sh
echo "→ Running tests..."
cargo test --quiet
EOF

# Make them all executable
chmod +x .samoyed/hooks.d/*.pre-commit
```

Result:
```bash
$ git commit -m "add feature"
→ Checking format...
✓ Format OK
→ Running clippy...
✓ Lint OK
→ Running tests...
✓ Tests OK
[main abc123] add feature
```

## Combined with LFS

Use both hooks.d and LFS integration:

```bash
samoyed init --with-lfs --hooks-d
```

Execution order:
1. Git LFS commands
2. hooks.d/ scripts (your checks)
3. Main hook (if exists)

See [Combined Features](./combined-features.md) for details.

## Troubleshooting

### Hooks not running?

Check they're executable:
```bash
ls -l .samoyed/hooks.d/
```

Make them executable:
```bash
chmod +x .samoyed/hooks.d/*.pre-commit
```

### Wrong execution order?

Check filenames - order is lexicographic:
```bash
ls .samoyed/hooks.d/*.pre-commit
```

Should show:
```
10-format.pre-commit
20-lint.pre-commit
30-test.pre-commit
```

### Hook failing silently?

Check the hook's exit code:
```bash
.samoyed/hooks.d/10-format.pre-commit
echo $?  # Should be 0 for success
```

## Next Steps

- [Combined Features](./combined-features.md): Use hooks.d with LFS
- [Best Practices](./best-practices.md): Write great hooks
- [Use Cases](./use-cases.md): Real-world examples
