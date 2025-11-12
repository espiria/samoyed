# Installation

Samoyed can be installed through several methods. Choose the one that works best for your workflow.

## From Pre-built Binaries

**Recommended for most users**

Download the latest release from [GitHub Releases](https://github.com/nutthead/samoyed/releases):

```bash
# Linux (x86_64)
curl -L https://github.com/nutthead/samoyed/releases/latest/download/samoyed-linux-x86_64 -o samoyed
chmod +x samoyed
sudo mv samoyed /usr/local/bin/

# macOS (Intel)
curl -L https://github.com/nutthead/samoyed/releases/latest/download/samoyed-macos-x86_64 -o samoyed
chmod +x samoyed
sudo mv samoyed /usr/local/bin/

# macOS (Apple Silicon)
curl -L https://github.com/nutthead/samoyed/releases/latest/download/samoyed-macos-arm64 -o samoyed
chmod +x samoyed
sudo mv samoyed /usr/local/bin/

# Windows (PowerShell)
curl https://github.com/nutthead/samoyed/releases/latest/download/samoyed-windows-x86_64.exe -o samoyed.exe
# Move to a directory in your PATH
```

## From Source with Cargo

**For Rust developers or latest features**

```bash
# Install from crates.io
cargo install samoyed

# Or build from source
git clone https://github.com/nutthead/samoyed.git
cd samoyed
cargo install --path .
```

### Build Requirements
- Rust 1.70 or later
- Git (for testing)

## Via Package Managers

### Homebrew (macOS/Linux)
```bash
# Coming soon
brew install samoyed
```

### Cargo-binstall (faster than building)
```bash
cargo binstall samoyed
```

## Verify Installation

Check that Samoyed is installed correctly:

```bash
samoyed --version
```

You should see output like:
```
samoyed 0.2.3
```

## Optional: Install Git LFS

For Git LFS integration features, install Git LFS:

```bash
# macOS
brew install git-lfs

# Ubuntu/Debian
sudo apt-get install git-lfs

# Fedora
sudo dnf install git-lfs

# Windows (with Chocolatey)
choco install git-lfs

# Windows (with Scoop)
scoop install git-lfs
```

Then initialize it:
```bash
git lfs install
```

## Next Steps

Now that Samoyed is installed:

- [Quick Start](./quick-start.md): Set up your first hooks
- [Basic Usage](./basic-usage.md): Learn the commands

## Uninstallation

### Binary Installation
```bash
sudo rm /usr/local/bin/samoyed
```

### Cargo Installation
```bash
cargo uninstall samoyed
```

### Repository Cleanup
To remove Samoyed from a specific repository:
```bash
# This removes the hooks directory and resets Git config
rm -rf .samoyed
git config --unset core.hooksPath
```
