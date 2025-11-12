# Introduction

**Samoyed** is a minimal, cross-platform Git hooks manager written in Rust. It provides a simple, consistent interface for managing client-side Git hooks without the complexity and overhead of larger tools.

## Why Samoyed?

- **Single Binary**: No runtime dependencies, just one executable
- **Cross-Platform**: Works on Linux, macOS, and Windows
- **Minimal**: ~1200 lines of Rust code, focused on doing one thing well
- **Git LFS Support**: First-class integration with Git Large File Storage
- **Hook Composition**: Chain multiple hooks together with the hooks.d pattern
- **Zero Configuration**: Works out of the box with sensible defaults
- **Fast**: Rust performance with optimized release builds

## Key Features

### Core Functionality
- Initialize hooks in any Git repository
- Custom hook directory names
- POSIX-compliant wrapper scripts
- Bypass mode for emergency situations

### Advanced Features
- **Git LFS Integration**: Automatic detection and integration of Git LFS commands
- **Hook Composition**: Run multiple hooks in sequence with the hooks.d pattern
- **Existing Hook Detection**: Import hooks from other tools seamlessly

### Developer Experience
- Simple CLI interface
- Clear error messages
- Comprehensive test suite
- Well-documented codebase

## Philosophy

Samoyed follows these principles:

1. **Simplicity**: Single-file Rust implementation, avoiding unnecessary complexity
2. **Reliability**: Comprehensive testing (26 unit tests, 15 integration tests)
3. **Minimalism**: No feature creep, focused scope
4. **Standards**: POSIX-compliant shell scripts, standard Git hooks

## Project Status

Samoyed is actively maintained and production-ready. It powers Git workflows for individual developers and teams.

## Quick Example

```bash
# Initialize hooks
samoyed init

# Create a pre-commit hook
cat > .samoyed/pre-commit <<'EOF'
#!/usr/bin/env sh
cargo fmt --check
cargo clippy -- -D warnings
EOF
chmod +x .samoyed/pre-commit

# Hooks run automatically
git commit -m "test"
```

## Next Steps

- [Installation](./installation.md): Get Samoyed on your system
- [Quick Start](./quick-start.md): Your first hooks in 5 minutes
- [Basic Usage](./basic-usage.md): Learn the fundamentals
