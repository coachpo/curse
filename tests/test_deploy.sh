#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file_exists() {
  [ -f "$1" ] || fail "expected file to exist: $1"
}

assert_executable() {
  [ -x "$1" ] || fail "expected file to be executable: $1"
}

assert_path_missing() {
  [ ! -e "$1" ] || fail "expected path to be absent: $1"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain '$needle'"
}

assert_file_contains() {
  local file="$1"
  local needle="$2"
  grep -Fq "$needle" "$file" || fail "expected $file to contain '$needle'"
}

assert_file_not_contains() {
  local file="$1"
  local needle="$2"
  if grep -Fq "$needle" "$file"; then
    fail "expected $file to not contain '$needle'"
  fi
}

assert_log_contains() {
  local needle="$1"
  if ! grep -Fq "$needle" "$FIXTURE_LOG"; then
    printf -- '--- log contents ---\n' >&2
    sed -n '1,200p' "$FIXTURE_LOG" >&2
    fail "expected $FIXTURE_LOG to contain '$needle'"
  fi
}

assert_log_not_contains() {
  assert_file_not_contains "$FIXTURE_LOG" "$1"
}

check_repo_artifacts() {
  assert_file_exists "$ROOT_DIR/deploy.sh"
  assert_executable "$ROOT_DIR/deploy.sh"
  assert_path_missing "$ROOT_DIR/Makefile"

  assert_file_contains "$ROOT_DIR/README.md" "./deploy.sh"
  assert_file_not_contains "$ROOT_DIR/README.md" "Using Make"
  assert_file_not_contains "$ROOT_DIR/README.md" "make start-"
  assert_file_not_contains "$ROOT_DIR/README.md" "Nacos"

  assert_file_contains "$ROOT_DIR/AGENTS.md" "deploy.sh"
  assert_file_not_contains "$ROOT_DIR/AGENTS.md" "Makefile"
  assert_file_not_contains "$ROOT_DIR/AGENTS.md" "make start-"
  assert_file_not_contains "$ROOT_DIR/prism-b/clone-prism-a-volume.sh" "make stop-"
}

check_compose_version_vars() {
  assert_file_contains "$ROOT_DIR/asspp/compose.yml" 'image: ghcr.io/lakr233/assppweb:${ASSPP_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/bark/compose.yml" 'image: finab/bark-server:${BARK_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/clay/compose.yml" 'image: ghcr.io/coachpo/clay:${CLAY_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/cli-proxy-api/compose.yml" 'image: eceasy/cli-proxy-api:${CLI_PROXY_API_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/mermaid/compose.yml" 'image: ghcr.io/mermaid-js/mermaid-live-editor:${MERMAID_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/n8n/compose.yml" 'image: docker.n8n.io/n8nio/n8n:${N8N_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/portainer/compose.yml" 'image: portainer/portainer-ce:${PORTAINER_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/registry/compose.yml" 'image: registry:${REGISTRY_VERSION:-latest}'

  assert_file_contains "$ROOT_DIR/herald/compose.yml" 'image: ghcr.io/coachpo/herald-frontend:${HERALD_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/herald/compose.yml" 'image: ghcr.io/coachpo/herald-backend:${HERALD_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/prism-a/compose.yml" 'image: ghcr.io/coachpo/prism-backend:${PRISM_A_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/prism-a/compose.yml" 'image: ghcr.io/coachpo/prism-frontend:${PRISM_A_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/prism-b/compose.yml" 'image: ghcr.io/coachpo/prism-backend:${PRISM_B_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/prism-b/compose.yml" 'image: ghcr.io/coachpo/prism-frontend:${PRISM_B_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/swiperflix/compose.yml" 'image: ghcr.io/coachpo/swiperflix-player:${SWIPERFLIX_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/swiperflix/compose.yml" 'image: ghcr.io/coachpo/swiperflix-gateway:${SWIPERFLIX_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/whisper/compose.yml" 'image: ghcr.io/coachpo/last-whisper-backend:${WHISPER_VERSION:-latest}'
  assert_file_contains "$ROOT_DIR/whisper/compose.yml" 'image: ghcr.io/coachpo/last-whisper-frontend:${WHISPER_VERSION:-latest}'

  assert_file_contains "$ROOT_DIR/herald/compose.yml" 'image: nginx:1.27-alpine'
  assert_file_contains "$ROOT_DIR/prism-a/compose.yml" 'image: postgres:16-alpine'
  assert_file_contains "$ROOT_DIR/prism-a/compose.yml" 'image: nginx:1.27-alpine'
  assert_file_contains "$ROOT_DIR/prism-b/compose.yml" 'image: postgres:16-alpine'
  assert_file_contains "$ROOT_DIR/prism-b/compose.yml" 'image: nginx:1.27-alpine'
  assert_file_contains "$ROOT_DIR/swiperflix/compose.yml" 'image: nginx:1.27-alpine'
  assert_file_contains "$ROOT_DIR/whisper/compose.yml" 'image: caddy:2.8-alpine'
}

create_fixture() {
  FIXTURE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/deploy-test.XXXXXX")"
  FIXTURE_BIN="$FIXTURE_ROOT/bin"
  FIXTURE_LOG="$FIXTURE_ROOT/docker.log"
  CLONE_LOG="$FIXTURE_ROOT/clone.log"
  mkdir -p "$FIXTURE_BIN" "$FIXTURE_ROOT/alpha-service" "$FIXTURE_ROOT/apps/gamma-app" "$FIXTURE_ROOT/delta-env" "$FIXTURE_ROOT/prism-b"
  cp "$ROOT_DIR/deploy.sh" "$FIXTURE_ROOT/deploy.sh"
  chmod +x "$FIXTURE_ROOT/deploy.sh"

  cat <<'EOF' > "$FIXTURE_ROOT/alpha-service/compose.yml"
services:
  alpha-service:
    image: ghcr.io/example/alpha:${ALPHA_SERVICE_VERSION:-latest}
EOF

  cat <<'EOF' > "$FIXTURE_ROOT/apps/gamma-app/docker-compose.yaml"
services:
  gamma-app:
    image: ghcr.io/example/gamma:${APPS_GAMMA_APP_VERSION:-latest}
EOF

  cat <<'EOF' > "$FIXTURE_ROOT/prism-b/compose.yml"
services:
  backend:
    image: ghcr.io/example/prism-backend:${PRISM_B_VERSION:-latest}
  frontend:
    image: ghcr.io/example/prism-frontend:${PRISM_B_VERSION:-latest}
  reverse-proxy:
    image: nginx:1.27-alpine
  postgres:
    image: postgres:16-alpine
EOF

  cat <<'EOF' > "$FIXTURE_ROOT/delta-env/compose.yml"
services:
  delta-env:
    image: ghcr.io/example/envapp:${DELTA_ENV_VERSION:-latest}
    env_file:
      - ./missing.env
EOF

  cat <<'EOF' > "$FIXTURE_ROOT/prism-b/clone-prism-a-volume.sh"
#!/usr/bin/env bash
set -euo pipefail
printf 'clone stub\n'
printf 'called\n' > "$TEST_CLONE_LOG"
EOF
  chmod +x "$FIXTURE_ROOT/prism-b/clone-prism-a-volume.sh"

  cat <<'EOF' > "$FIXTURE_BIN/docker"
#!/usr/bin/env bash
set -euo pipefail

log_file="${FIXTURE_LOG:?}"

compose_file=''
if [ "$#" -ge 3 ] && [ "$1" = "compose" ] && [ "$2" = "-f" ]; then
  compose_file="$3"
  shift 3
fi

service_version=''
  case "$compose_file" in
    alpha-service/*) service_version="ALPHA_SERVICE_VERSION=${ALPHA_SERVICE_VERSION:-}" ;;
    apps/gamma-app/*) service_version="APPS_GAMMA_APP_VERSION=${APPS_GAMMA_APP_VERSION:-}" ;;
    prism-b/*) service_version="PRISM_B_VERSION=${PRISM_B_VERSION:-}" ;;
    delta-env/*) service_version="DELTA_ENV_VERSION=${DELTA_ENV_VERSION:-}" ;;
esac

if [ "$#" -ge 1 ] && [ "$1" = "compose" ]; then
  printf 'unexpected nested compose invocation\n' >&2
  exit 1
fi

if [ -n "$compose_file" ]; then
  command_name="$1"
  shift
  action="$command_name"
  if [ "$#" -gt 0 ]; then
    action="$action $*"
  fi
  printf 'compose|%s|%s|%s\n' "$compose_file" "$action" "$service_version" >> "$log_file"
  case "$command_name" in
    pull|down|logs|up)
      exit 0
      ;;
    ps)
      if [ "$1" = "--format" ] && [ "$2" = "json" ]; then
        case "$compose_file" in
          alpha-service/*)
            printf '[{"Service":"alpha-service","Publishers":[{"URL":"0.0.0.0","PublishedPort":18080,"TargetPort":8080,"Protocol":"tcp"}]}]\n'
            ;;
          apps/gamma-app/*)
            printf '[{"Service":"gamma-app","Publishers":[{"URL":"0.0.0.0","PublishedPort":19090,"TargetPort":9090,"Protocol":"tcp"}]}]\n'
            ;;
          delta-env/*)
            printf '[{"Service":"delta-env","Publishers":[]}]\n'
            ;;
          prism-b/*)
            printf '[{"Service":"reverse-proxy","Publishers":[{"URL":"0.0.0.0","PublishedPort":18088,"TargetPort":80,"Protocol":"tcp"}]}]\n'
            ;;
        esac
      else
        printf 'service|0.0.0.0:1234->80/tcp\n'
      fi
      exit 0
      ;;
    config)
      if [ "$1" = "--images" ]; then
        case "$compose_file" in
          alpha-service/*)
            printf 'ghcr.io/example/alpha:%s\n' "${ALPHA_SERVICE_VERSION:-latest}"
            ;;
          apps/gamma-app/*)
            printf 'ghcr.io/example/gamma:%s\n' "${APPS_GAMMA_APP_VERSION:-latest}"
            ;;
          delta-env/*)
            printf 'missing env file\n' >&2
            exit 1
            ;;
          prism-b/*)
            printf 'postgres:16-alpine\n'
            printf 'ghcr.io/example/prism-backend:%s\n' "${PRISM_B_VERSION:-latest}"
            printf 'ghcr.io/example/prism-frontend:%s\n' "${PRISM_B_VERSION:-latest}"
            printf 'nginx:1.27-alpine\n'
            ;;
        esac
        exit 0
      fi
      ;;
  esac
fi

if [ "$1" = "image" ] && [ "$2" = "ls" ]; then
  printf 'ghcr.io/example/alpha|<none>|sha256:alpha-old\n'
  printf 'ghcr.io/example/alpha|latest|sha256:alpha-latest\n'
  printf 'ghcr.io/example/gamma|<none>|sha256:gamma-in-use\n'
  printf 'ghcr.io/example/prism-backend|<none>|sha256:prism-old\n'
  printf 'ghcr.io/example/envapp|<none>|sha256:env-old\n'
  printf 'ghcr.io/example/unrelated|<none>|sha256:unrelated-old\n'
  exit 0
fi

if [ "$1" = "ps" ] && [ "$2" = "-aq" ] && [ "$3" = "--filter" ]; then
  case "$4" in
    ancestor=sha256:gamma-in-use)
      printf 'container-1\n'
      ;;
  esac
  exit 0
fi

if [ "$1" = "image" ] && [ "$2" = "rm" ]; then
  printf 'image-rm|%s\n' "$3" >> "$log_file"
  exit 0
fi

printf 'unsupported docker invocation: %s\n' "$*" >&2
exit 1
EOF
  chmod +x "$FIXTURE_BIN/docker"

  ORIGINAL_PATH="$PATH"
  export FIXTURE_LOG TEST_CLONE_LOG="$CLONE_LOG"
  export PATH="$FIXTURE_BIN:$PATH"
}

destroy_fixture() {
  PATH="$ORIGINAL_PATH"
  rm -rf "$FIXTURE_ROOT"
}

check_cli_behavior() {
  local output=''

   output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh services)"
   assert_contains "$output" 'alpha-service'
   assert_contains "$output" 'apps/gamma-app'
   assert_contains "$output" 'delta-env'
   assert_contains "$output" 'prism-b'

  output="$(cd "$ROOT_DIR" && bash ./deploy.sh ports)"
  assert_contains "$output" 'CLI_PROXY_API_PORT'
  assert_contains "$output" 'PRISM_B_PORT'

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh status)"
  assert_contains "$output" 'alpha-service'
  assert_log_contains 'compose|alpha-service/compose.yml|ps|ALPHA_SERVICE_VERSION='

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh start alpha-service --version 1.2.3)"
  assert_contains "$output" 'alpha-service'
  assert_log_contains 'compose|alpha-service/compose.yml|pull|ALPHA_SERVICE_VERSION=1.2.3'
  assert_log_contains 'compose|alpha-service/compose.yml|up -d|ALPHA_SERVICE_VERSION=1.2.3'

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh alpha-service start --version 7.8.9)"
  assert_contains "$output" 'alpha-service'
  assert_log_contains 'compose|alpha-service/compose.yml|pull|ALPHA_SERVICE_VERSION=7.8.9'
  assert_log_contains 'compose|alpha-service/compose.yml|up -d|ALPHA_SERVICE_VERSION=7.8.9'

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh start alpha-service)"
  assert_log_contains 'compose|alpha-service/compose.yml|pull|ALPHA_SERVICE_VERSION=latest'
  assert_log_contains 'compose|alpha-service/compose.yml|up -d|ALPHA_SERVICE_VERSION=latest'

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh apps/gamma-app restart)"
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|down|APPS_GAMMA_APP_VERSION='
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|pull|APPS_GAMMA_APP_VERSION=latest'
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|up -d|APPS_GAMMA_APP_VERSION=latest'

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh restart apps/gamma-app --version 4.5.6)"
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|down|APPS_GAMMA_APP_VERSION='
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|pull|APPS_GAMMA_APP_VERSION=4.5.6'
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|up -d|APPS_GAMMA_APP_VERSION=4.5.6'

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh force apps/gamma-app --version 4.5.6)"
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|down -v --remove-orphans|APPS_GAMMA_APP_VERSION='
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|pull|APPS_GAMMA_APP_VERSION=4.5.6'
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|up -d|APPS_GAMMA_APP_VERSION=4.5.6'

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh apps/gamma-app force)"
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|down -v --remove-orphans|APPS_GAMMA_APP_VERSION='
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|pull|APPS_GAMMA_APP_VERSION=latest'
  assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|up -d|APPS_GAMMA_APP_VERSION=latest'

  : > "$FIXTURE_LOG"
   output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh logs apps/gamma-app)"
   assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|logs -f|APPS_GAMMA_APP_VERSION='

  : > "$FIXTURE_LOG"
   output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh stop apps/gamma-app)"
   assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|down|APPS_GAMMA_APP_VERSION='

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh start-all --version 9.9.9)"
  assert_log_contains 'compose|alpha-service/compose.yml|pull|ALPHA_SERVICE_VERSION=9.9.9'
   assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|pull|APPS_GAMMA_APP_VERSION=9.9.9'
  assert_log_contains 'compose|prism-b/compose.yml|pull|PRISM_B_VERSION=9.9.9'

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh stop-all)"
  assert_log_contains 'compose|alpha-service/compose.yml|down|ALPHA_SERVICE_VERSION='
   assert_log_contains 'compose|apps/gamma-app/docker-compose.yaml|down|APPS_GAMMA_APP_VERSION='
  assert_log_contains 'compose|prism-b/compose.yml|down|PRISM_B_VERSION='

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && printf '1\n1\n\n' | bash ./deploy.sh)"
  assert_log_contains 'compose|alpha-service/compose.yml|pull|ALPHA_SERVICE_VERSION=latest'

  : > "$FIXTURE_LOG"
  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh prune-images)"
  assert_contains "$output" 'Removed 3 unused untagged discovered service image(s).'
  assert_log_contains 'image-rm|sha256:alpha-old'
  assert_log_contains 'image-rm|sha256:env-old'
  assert_log_contains 'image-rm|sha256:prism-old'
  assert_log_not_contains 'image-rm|sha256:gamma-in-use'
  assert_log_not_contains 'image-rm|sha256:unrelated-old'

  output="$(cd "$FIXTURE_ROOT" && bash ./deploy.sh clone-prism-b-from-prism-a)"
  assert_contains "$output" 'clone stub'
  assert_file_contains "$CLONE_LOG" 'called'
}

main() {
  check_repo_artifacts
  check_compose_version_vars
  create_fixture
  trap destroy_fixture EXIT
  check_cli_behavior
  printf 'PASS\n'
}

main "$@"
