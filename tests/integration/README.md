# Samoyed Integration Tests

This directory contains integration tests for Samoyed. Tests verify the complete workflow including initialization, hook execution, and various edge cases.

## Running Tests

### Local Execution (Serial)

Run all tests locally in serial mode:

```bash
# From repository root
cd tests/integration
for test in 0*.sh; do ./"$test"; done

# Or using Make
make test-integration
```

### Docker Execution (Parallel)

**Recommended approach** for fast, isolated testing:

```bash
# Build image and run all tests in parallel
make test-docker-parallel

# Or directly:
bash tests/integration/run-parallel-docker.sh
```

**Benefits:**
- Tests run in parallel (~10x faster)
- Complete isolation (no host contamination)
- Reproducible environment
- No local Rust toolchain needed

### Docker Execution (Serial)

Run tests one at a time in Docker:

```bash
make test-docker
```

### Docker Compose

Alternative orchestration using Docker Compose:

```bash
make test-docker-compose

# Or directly:
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
docker-compose -f docker-compose.test.yml down
```

### Running Individual Tests

#### Locally

```bash
cd tests/integration
./01_default.sh
./02_custom_dir.sh --keep  # Keep temp directory for debugging
```

#### In Docker

```bash
docker build -t samoyed-test .
docker run --rm -e TEST_NAME=01_default.sh samoyed-test
```

## Test Suite

| Test | Description |
|------|-------------|
| `01_default.sh` | Basic initialization and hook execution |
| `02_custom_dir.sh` | Custom directory names and nested paths |
| `03_from_subdir.sh` | Initialization from subdirectories |
| `04_not_git_dir.sh` | Error handling for non-git directories |
| `05_git_not_found.sh` | Handling missing git command |
| `06_command_not_found.sh` | Command not found error handling |
| `07_strict_mode.sh` | Shell strict mode compatibility |
| `08_samoyed_0.sh` | SAMOYED=0 bypass functionality |
| `09_init.sh` | Init command comprehensive tests |
| `10_time.sh` | Performance and timing tests |

## Architecture

### Test Structure

Each test:
1. Creates isolated temporary git repository
2. Initializes Samoyed
3. Tests specific functionality
4. Cleans up (unless `--keep` flag used)

### Helper Functions

`functions.sh` provides:
- `setup()` - Create test environment
- `cleanup()` - Remove test artifacts
- `init_samoyed()` - Initialize Samoyed in test repo
- `ok()`, `error()` - Test assertions
- Container detection for Docker execution

### Containerization

**Dockerfile** (multi-stage build):
```
Stage 1 (builder): Compile Samoyed binary
Stage 2 (test-runner): Minimal Debian + Git + compiled binary
```

**Key features:**
- Binary built once, reused across all tests
- Tests run in isolated containers
- No shared state between tests
- Clean git configuration per container

## Performance

Typical execution times:

| Method | Duration | Notes |
|--------|----------|-------|
| Local serial | ~30-40s | All tests run sequentially |
| Docker serial | ~35-45s | Sequential with container overhead |
| Docker parallel | ~8-12s | All tests run simultaneously |
| Docker Compose | ~10-15s | Similar to parallel script |

## Troubleshooting

### Test Failures

View logs for failed tests:

```bash
# Local execution shows output directly

# Docker parallel execution shows last 50 lines of failed tests
bash tests/integration/run-parallel-docker.sh
```

### Debugging

Keep temporary directory for inspection:

```bash
# Local
./01_default.sh --keep

# Docker (requires running interactively)
docker run --rm -it -e TEST_NAME=01_default.sh samoyed-test bash
# Then manually run: /tests/integration/01_default.sh
```

### Container Issues

Build container without cache:

```bash
docker build --no-cache -t samoyed-test -f Dockerfile .
```

Check if running in container:

```bash
# Inside container, this returns 0:
is_containerized && echo "In container" || echo "Not in container"
```

## CI Integration

Tests run in parallel in GitHub Actions:

```yaml
- name: Run integration tests (parallel)
  run: make test-docker-parallel
```

See `.github/workflows/ci.yml` for full configuration.

## Adding New Tests

1. Create `tests/integration/XX_name.sh`
2. Follow existing test structure
3. Add to `TEST_SCRIPTS` array in `run-parallel-docker.sh`
4. Add service to `docker-compose.test.yml`
5. Test locally before committing

Example template:

```bash
#!/usr/bin/env sh
# Test: Brief description

integration_script_dir="$(cd "$(dirname "$0")" && pwd)"
integration_repo_root="$(cd "$integration_script_dir/../.." && pwd)"
cd "$integration_repo_root"
. "$integration_repo_root/tests/integration/functions.sh"

parse_common_args "$@"
build_samoyed
setup

# Your test code here
echo "Testing: Feature X"
init_samoyed
ok "Feature X works"

cleanup
```

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `SAMOYED_BIN` | Path to binary | `target/release/samoyed` |
| `SAMOYED_TEST_CONTAINER` | Force container mode | unset |
| `SAMOYED_TEST_IMAGE` | Docker image name | `samoyed-test:latest` |
| `KEEP_WORKDIR` | Keep temp dir | `false` |

## Requirements

### Local Execution
- Rust toolchain (for building)
- Git
- Bash/sh
- Standard Unix utilities

### Docker Execution
- Docker or Podman
- No Rust toolchain needed
- Works on Linux, macOS, Windows (WSL)
