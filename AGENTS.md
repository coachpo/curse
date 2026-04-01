# Curse Repository Agent Guide

> **For coding agents:** Use this file as the repo map and workflow contract. Follow the repo's shell-first conventions and verify every claim against files in this repository.

**Goal:** Keep the Docker Compose stacks, deploy script, and docs aligned.

**Architecture:** This repo is an infra-only Compose monorepo. Each service directory owns one deployable stack, its compose file, and any service-local config or notes. `deploy.sh` is the canonical entry point, service discovery is automatic, and the README mirrors the operator-facing parts of that contract.

**Tech Stack:** Bash, Docker Compose, YAML, Markdown.

---

## Repo shape

- `deploy.sh` is the canonical deployment interface.
- Services are discovered from repo subdirectories that contain `compose.yml`, `compose.yaml`, `docker-compose.yml`, or `docker-compose.yaml`.
- `.git` and `.sisyphus` are skipped by discovery.
- Service-local `AGENTS.md` files exist for `herald/`, `prism-a/`, `prism-b/`, `swiperflix/`, and `whisper/`.
- `README.md` is the operator-facing summary and port table.
- `tests/test_deploy.sh` is the main repo check and encodes the current deployment contract.

## Non-negotiable repo rules

- `deploy.sh start <service>` always runs `docker compose pull` before `up -d`.
- Port defaults must stay in sync between `README.md` and `deploy.sh ports`.
- App image tags use path-derived version vars, for example `HERALD_VERSION`, `PRISM_A_VERSION`, `PRISM_B_VERSION`, `SWIPERFLIX_VERSION`, and `WHISPER_VERSION`.
- Those version vars are derived from the service path, uppercased, with non-alphanumeric characters converted to `_`, then suffixed with `_VERSION`.
- App images default to `latest` when no version is supplied.
- Mixed stacks keep pinned dependency images pinned, such as `nginx`, `postgres`, `caddy`, and other base services already fixed in compose files.
- Runtime secrets like `.env`, `backend.env`, and credential files must never be committed.
- Prism B clone operations require Prism B to be stopped first.
- No Cursor rules, `.cursorrules`, or Copilot instructions were found in this repo.

## What to inspect first

- `deploy.sh`, for CLI behavior, discovery, version injection, port reporting, and clone behavior.
- `tests/test_deploy.sh`, for the current test story and repository conventions.
- `README.md`, for the operator summary and the default port map.
- `AGENTS.md` files under service directories, when touching service-local behavior or docs.
- Representative compose files in `herald/`, `prism-a/`, `prism-b/`, `swiperflix/`, and `whisper/`, because they show the real image tags, restart policy, port exposure, and proxy style.
- `.gitignore`, for the repo's secrets and runtime-file rules.

## Code style and conventions

- Bash scripts use `#!/usr/bin/env bash`, `set -euo pipefail`, and small focused functions.
- Prefer standalone scripts with local helper functions over sourcing sibling shell files. This repo's committed shell entry points are self-contained.
- Prefer `printf` over `echo` for user-facing output. Existing errors use `die()` and test failures use `fail()`.
- Quote variable expansions and paths.
- Use `local` variables inside functions.
- Use arrays for lists and option sets when order matters, as in `COMPOSE_CANDIDATES`, `SERVICE_NAMES`, and `SERVICE_FILES`.
- Keep non-fatal behavior explicit. In this repo, `|| true` is only acceptable for intentional best-effort cleanup or inspection.
- Function names are lower_snake_case. Env vars and constants are upper snake case.
- Service names come from repo-relative directory paths, so keep directory names stable and predictable.
- Version env vars are path-derived, uppercased, with non-alphanumeric characters converted to `_`, then suffixed with `_VERSION`.
- Compose files use `${ENV_VAR:-default}` interpolation for host ports and app image tags.
- Keep pinned dependency images pinned. Only the app images should move with the per-service version variable.
- Use lowercase, direct prose in Markdown.
- Keep tables simple and factual.
- When documenting ports, env vars, or commands, use the exact strings supported by `deploy.sh` and the compose files.
- Avoid inventing wrapper tooling, Make targets, package-manager workflows, or CI surfaces that do not exist here.

## Build, lint, and test commands

There is no repo-wide build step and no repo-wide lint command.

- Full test suite: `bash tests/test_deploy.sh`
- Shell syntax check for the deploy script: `bash -n deploy.sh`
- Shell syntax check for the repo test script: `bash -n tests/test_deploy.sh`
- Compose config validation for a service: `docker compose -f <service>/compose.yml config`
- Service inventory: `./deploy.sh services`
- Port summary: `./deploy.sh ports`
- Full status view: `./deploy.sh status`

## Single-test story

The repo only has one committed shell test entry point, `tests/test_deploy.sh`. That script defines helper functions such as `check_repo_artifacts`, `check_compose_version_vars`, `create_fixture`, and `check_cli_behavior`, then runs them in `main()`.

There is no first-class single-test runner. For focused checks, reuse those helper functions directly from a temporary sourced copy of the test file.

Example: run only the repo artifact assertions from the repo root:

```bash
python3 - <<'PY'
from pathlib import Path
lines = Path("tests/test_deploy.sh").read_text().splitlines()
if lines and lines[-1].strip() == 'main "$@"':
    lines = lines[:-1]
Path("/tmp/test_deploy_funcs.sh").write_text("\n".join(lines) + "\n")
PY

source /tmp/test_deploy_funcs.sh
ROOT_DIR="$PWD"
check_repo_artifacts
```

For helpers that need fixtures, add the setup and teardown calls before invoking the helper:

```bash
source /tmp/test_deploy_funcs.sh
ROOT_DIR="$PWD"
create_fixture
trap destroy_fixture EXIT
check_cli_behavior
```

## Practical command patterns

```bash
# List services
./deploy.sh services

# Show the documented port table
./deploy.sh ports

# Validate one compose file
docker compose -f prism-a/compose.yml config

# Run shell syntax checks
bash -n deploy.sh
bash -n tests/test_deploy.sh

# Run the full repo test script
bash tests/test_deploy.sh
```

## Service-specific notes

- Herald uses `backend.env`, a hardened nginx edge, and deliberate read-only style hardening.
- Prism A uses `backend.env`, an nginx gateway, and internal Postgres.
- Prism B mirrors Prism A, but it also publishes PostgreSQL on `PRISM_B_POSTGRES_PORT` and includes `clone-prism-a-volume.sh`.
- Swiperflix uses an nginx proxy and an optional host-local OpenList backend.
- Whisper uses Caddy and expects Google credentials at `./secrets/google-credentials.json`.

## Docs alignment rules

- Keep `README.md` operator-facing and aligned with the same deploy and port contract.
- When ports, runtime files, or version-variable rules change, update both `README.md` and the relevant compose file or helper in `deploy.sh`.
- Keep service-local guidance inside each service directory when the behavior is specific to that stack.

## What not to do

- Do not commit runtime secrets or credential files.
- Do not add custom build wrapper workflows or pretend they exist.
- Do not claim npm, pytest, or root-level CI workflows exist here.
- Do not change default ports unless the docs and `deploy.sh ports` are updated together.
- Do not retag pinned dependency images just to simplify versioning.
