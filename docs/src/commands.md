# Command Reference

Complete reference for all Samoyed commands.

## samoyed init

Initialize Git hooks in a repository.

### Syntax

```bash
samoyed init [OPTIONS] [DIRNAME]
```

### Arguments

- `[DIRNAME]` - Optional custom directory name (default: `.samoyed`)

### Options

- `--with-lfs` - Force enable Git LFS integration
- `--no-lfs` - Force disable Git LFS integration
- `--hooks-d` - Enable hook composition mode

### Examples

```bash
# Basic initialization
samoyed init

# Custom directory
samoyed init my-hooks

# With LFS integration
samoyed init --with-lfs

# With hook composition
samoyed init --hooks-d

# Combined features
samoyed init --with-lfs --hooks-d
```

### What It Does

1. Detects Git repository root
2. Creates hook directory structure
3. Installs wrapper scripts
4. Configures `git config core.hooksPath`
5. Creates sample pre-commit hook
6. Optionally integrates Git LFS
7. Optionally sets up hooks.d/

### Exit Codes

- `0` - Success
- `1` - Error (not a git repository, permission denied, etc.)

## samoyed lfs

Manage Git LFS integration.

### Subcommands

#### lfs status

Show LFS integration status.

```bash
samoyed lfs status
```

Output example:
```
Git LFS installation: ✓
Repository LFS config: ✓ Configured
Samoyed hooks initialized: ✓ in .samoyed/_
LFS integration: Enabled
Hook composition mode: Disabled
```

#### lfs enable

Enable LFS integration in existing hooks.

```bash
samoyed lfs enable
```

Requirements:
- Samoyed must be initialized
- Git LFS should be installed

#### lfs disable

Disable LFS integration.

```bash
samoyed lfs disable
```

Removes LFS commands from hooks while preserving other logic.

### Examples

```bash
# Check current status
samoyed lfs status

# Enable LFS
samoyed lfs enable

# Disable LFS
samoyed lfs disable
```

## Global Options

### --help, -h

Show help message.

```bash
samoyed --help
samoyed init --help
samoyed lfs --help
```

### --version, -V

Show version information.

```bash
samoyed --version
```

## Environment Variables

These environment variables affect Samoyed's behavior:

### SAMOYED

Control hook execution:

- `SAMOYED=0` - Bypass all hooks (emergency mode)
- `SAMOYED=2` - Enable debug mode (verbose shell output)

```bash
# Skip hooks once
SAMOYED=0 git commit -m "emergency fix"

# Debug hooks
SAMOYED=2 git commit -m "test"
```

### XDG_CONFIG_HOME

Override config directory location (default: `~/.config`):

```bash
export XDG_CONFIG_HOME=~/my-config
```

Config file: `${XDG_CONFIG_HOME}/samoyed/init.sh`

## Exit Codes

Standard exit codes used by Samoyed:

- `0` - Success
- `1` - General error
- `2` - Command line usage error

## See Also

- [Basic Usage](./basic-usage.md)
- [Git LFS Integration](./lfs-integration.md)
- [Hook Composition](./hook-composition.md)
- [Environment Variables](./environment-variables.md)
