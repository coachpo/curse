#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
COMPOSE_CANDIDATES=(compose.yml compose.yaml docker-compose.yml docker-compose.yaml)
SERVICE_NAMES=()
SERVICE_FILES=()
NORMALIZED_ARGS=()

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

discover_services() {
  local compose_path=""
  local service=""

  SERVICE_NAMES=()
  SERVICE_FILES=()

  while IFS= read -r compose_path; do
    [ -n "$compose_path" ] || continue
    service="${compose_path%/*}"
    SERVICE_NAMES+=("$service")
    SERVICE_FILES+=("$compose_path")
  done < <(
    find "$ROOT_DIR" \
      \( -path "$ROOT_DIR/.git" -o -path "$ROOT_DIR/.git/*" -o -path "$ROOT_DIR/.sisyphus" -o -path "$ROOT_DIR/.sisyphus/*" \) -prune \
      -o -type f \( -name 'compose.yml' -o -name 'compose.yaml' -o -name 'docker-compose.yml' -o -name 'docker-compose.yaml' \) \
      -print \
      | sed "s#^$ROOT_DIR/##" \
      | sort
  )

  [ "${#SERVICE_NAMES[@]}" -gt 0 ] || die "no services discovered under $ROOT_DIR"
}

compose_file_for_service() {
  local service="$1"
  local i=0

  for ((i = 0; i < ${#SERVICE_NAMES[@]}; i++)); do
    if [ "${SERVICE_NAMES[$i]}" = "$service" ]; then
      printf '%s\n' "${SERVICE_FILES[$i]}"
      return 0
    fi
  done

  return 1
}

require_service() {
  compose_file_for_service "$1" >/dev/null 2>&1 || die "unknown service '$1'"
}

version_var_name() {
  local service="$1"
  local prefix=""

  prefix="$(printf '%s' "$service" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9' '_')"
  printf '%s_VERSION\n' "$prefix"
}

run_compose() {
  local service="$1"
  shift

  (cd "$ROOT_DIR" && docker compose -f "$(compose_file_for_service "$service")" "$@")
}

run_compose_with_version() {
  local service="$1"
  local version="$2"
  local version_var=""
  shift 2

  version_var="$(version_var_name "$service")"
  (cd "$ROOT_DIR" && env "$version_var=$version" docker compose -f "$(compose_file_for_service "$service")" "$@")
}

print_running_ports() {
  local service="$1"
  local version="$2"
  local ports=""

  if command -v jq >/dev/null 2>&1; then
    ports="$({ run_compose_with_version "$service" "$version" ps --format json 2>/dev/null || true; } | jq -r '.[] | select((.Publishers | type) == "array" and (.Publishers | length) > 0) | "  - \(.Service): " + (.Publishers | map((if .URL and .URL != "" then .URL + ":" else "" end) + ((.PublishedPort // "unknown")|tostring) + "->" + ((.TargetPort // "unknown")|tostring) + "/" + ((.Protocol // "tcp")|tostring)) | join(", "))' 2>/dev/null || true)"
  else
    ports="$(run_compose_with_version "$service" "$version" ps --format '{{.Service}}|{{.Publishers}}' 2>/dev/null | awk -F'|' '
      $2 != "" && $2 != "[]" {
        service = $1;
        pubs = $2;
        if (pubs ~ /\{[^}]+\}/) {
          gsub(/^\[/, "", pubs);
          gsub(/\]$/, "", pubs);
          gsub(/\} \{/, "}\n{", pubs);
          n = split(pubs, items, /\n/);
          out = "";
          for (i = 1; i <= n; i++) {
            item = items[i];
            gsub(/[{}]/, "", item);
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", item);
            if (item == "") continue;
            m = split(item, f, /[[:space:]]+/);
            host = (m >= 1 && f[1] != "" ? f[1] : "0.0.0.0");
            target = (m >= 2 && f[2] != "" ? f[2] : "unknown");
            published = (m >= 3 && f[3] != "" ? f[3] : "unknown");
            proto = (m >= 4 && f[4] != "" ? f[4] : "tcp");
            if (host == "*") host = "0.0.0.0";
            if (host ~ /:/ && host !~ /^\[.*\]$/) host = "[" host "]";
            entry = host ":" published "->" target "/" proto;
            out = (out == "" ? entry : out ", " entry);
          }
          if (out != "") print "  - " service ": " out;
        } else {
          gsub(/^\[/, "", pubs);
          gsub(/\]$/, "", pubs);
          print "  - " service ": " pubs;
        }
      }
    ' || true)"
  fi

  if [ -n "$ports" ]; then
    printf '[%s] running on:\n%s\n' "$service" "$ports"
  else
    printf '[%s] started (no published host ports detected).\n' "$service"
  fi
}

list_services() {
  local service=""

  discover_services
  for service in "${SERVICE_NAMES[@]}"; do
    printf '%s\n' "$service"
  done
}

show_ports() {
  cat <<'EOF'
Port  | Service             | Env var                | App
------|---------------------|------------------------|-----------------------------------------------
5000  | Docker Registry     | REGISTRY_PORT          | Private container image registry
8000  | Portainer edge      | PORTAINER_EDGE_PORT    | Portainer edge tunnel endpoint
8080  | Bark                | BARK_PORT              | iOS push notification gateway
8081  | Herald (nginx)      | HERALD_PORT            | Message ingest and rule-based notifications
8083  | Mermaid             | MERMAID_PORT           | Live Mermaid diagram editor
8084  | Swiperflix (nginx)  | SWIPERFLIX_PORT        | TikTok-style video player stack
8085  | Whisper (caddy)     | WHISPER_PORT           | Dictation training platform
8086  | AssppWeb            | ASSPP_PORT             | iOS IPA install/acquisition web UI
8087  | Prism A (nginx)     | PRISM_A_PORT           | Self-hosted LLM proxy gateway
8088  | Prism B (nginx)     | PRISM_B_PORT           | Prism clone for A/B testing
8432  | Prism B Postgres    | PRISM_B_POSTGRES_PORT  | Direct host access to Prism B PostgreSQL
8089  | Clay                | CLAY_PORT              | OpenAI-compatible API proxy
8091  | n8n                 | N8N_PORT               | Workflow automation platform
8317  | CLIProxyAPI         | CLI_PROXY_API_PORT     | Multi-provider CLI/API proxy
9000  | Portainer UI        | PORTAINER_PORT         | Docker management dashboard
9443  | Portainer HTTPS     | PORTAINER_HTTPS_PORT   | Docker management dashboard (HTTPS)
EOF
}

show_status() {
  local service=""

  discover_services
  for service in "${SERVICE_NAMES[@]}"; do
    printf '=== %s ===\n' "$service"
    run_compose "$service" ps 2>/dev/null || printf '  (not running)\n'
    printf '\n'
  done
}

start_service() {
  local service="$1"
  local version="$2"

  require_service "$service"
  printf '[%s] pulling tag %s.\n' "$service" "$version"
  run_compose_with_version "$service" "$version" pull
  run_compose_with_version "$service" "$version" up -d
  print_running_ports "$service" "$version"
}

stop_service() {
  local service="$1"

  require_service "$service"
  run_compose "$service" down
}

restart_service() {
  local service="$1"
  local version="$2"

  stop_service "$service"
  start_service "$service" "$version"
}

logs_service() {
  local service="$1"

  require_service "$service"
  run_compose "$service" logs -f
}

start_all_services() {
  local version="$1"
  local service=""

  discover_services
  for service in "${SERVICE_NAMES[@]}"; do
    start_service "$service" "$version"
  done
}

stop_all_services() {
  local service=""

  discover_services
  for service in "${SERVICE_NAMES[@]}"; do
    stop_service "$service"
  done
}

prune_images() {
  local repos=""
  local repo=""
  local ids=""
  local id=""
  local removed=0
  local service=""
  local compose_file=""

  discover_services

  printf 'Removing unused untagged images for discovered services...\n'
  repos="$({
    for service in "${SERVICE_NAMES[@]}"; do
      compose_file="$(compose_file_for_service "$service")"
      awk '
        /^[[:space:]]*image:[[:space:]]*/ {
          ref = $0
          sub(/^[[:space:]]*image:[[:space:]]*/, "", ref)
          sub(/[[:space:]]+#.*$/, "", ref)
          gsub(/^"|"$/, "", ref)
          gsub(/^\047|\047$/, "", ref)
          gsub(/\$\{[^}]+\}/, "latest", ref)
          print ref
        }
      ' "$ROOT_DIR/$compose_file"
    done
  } | awk 'NF { ref = $0; sub(/@.*/, "", ref); if (match(ref, /:[^\/:]*$/)) ref = substr(ref, 1, RSTART - 1); print ref }' | sort -u)"

  if [ -z "$repos" ]; then
    printf 'No service image repositories discovered.\n'
    return 0
  fi

  while IFS= read -r repo; do
    [ -n "$repo" ] || continue
    ids="$(docker image ls --format '{{.Repository}}|{{.Tag}}|{{.ID}}' | awk -F'|' -v repo="$repo" '$1 == repo && $2 == "<none>" { print $3 }' | sort -u)"
    while IFS= read -r id; do
      [ -n "$id" ] || continue
      if [ -z "$(docker ps -aq --filter "ancestor=$id")" ]; then
        printf '  removing %s (%s)\n' "$repo" "$id"
        docker image rm "$id" >/dev/null || true
        removed=$((removed + 1))
      fi
    done <<EOF
$ids
EOF
  done <<EOF
$repos
EOF

  printf 'Removed %s unused untagged discovered service image(s).\n' "$removed"
}

clone_prism_b_from_prism_a() {
  (cd "$ROOT_DIR" && ./prism-b/clone-prism-a-volume.sh)
}

usage() {
  cat <<'EOF'
Usage: ./deploy.sh [command]

Interactive default:
  ./deploy.sh

Alternative single-service shorthand:
  ./deploy.sh <service> start [--version TAG]
  ./deploy.sh <service> stop
  ./deploy.sh <service> restart [--version TAG]
  ./deploy.sh <service> logs

Commands:
  ./deploy.sh services
  ./deploy.sh ports
  ./deploy.sh status
  ./deploy.sh start <service> [--version TAG]
  ./deploy.sh stop <service>
  ./deploy.sh restart <service> [--version TAG]
  ./deploy.sh logs <service>
  ./deploy.sh start-all [--version TAG]
  ./deploy.sh stop-all
  ./deploy.sh prune-images
  ./deploy.sh clone-prism-b-from-prism-a
EOF
}

parse_optional_version() {
  local usage_text="$1"
  shift

  if [ "$#" -eq 0 ]; then
    printf 'latest\n'
    return 0
  fi

  if [ "$#" -eq 2 ] && [ "$1" = '--version' ] && [ -n "$2" ]; then
    printf '%s\n' "$2"
    return 0
  fi

  die "$usage_text"
}

is_service_action() {
  case "$1" in
    start|stop|restart|logs) return 0 ;;
    *) return 1 ;;
  esac
}

normalize_service_first_args() {
  local service="$1"
  local action="$2"

  discover_services
  if compose_file_for_service "$service" >/dev/null 2>&1 && is_service_action "$action"; then
    shift 2
    NORMALIZED_ARGS=("$action" "$service" "$@")
    return 0
  fi

  return 1
}

choose_service_interactive() {
  local i=0
  local selection=""

  printf 'Select a service:\n' >&2
  for ((i = 0; i < ${#SERVICE_NAMES[@]}; i++)); do
    printf '  %s) %s\n' "$((i + 1))" "${SERVICE_NAMES[$i]}" >&2
  done
  printf '> ' >&2
  IFS= read -r selection
  case "$selection" in
    ''|*[!0-9]*) die "invalid service selection '$selection'" ;;
  esac
  if [ "$selection" -lt 1 ] || [ "$selection" -gt "${#SERVICE_NAMES[@]}" ]; then
    die "service selection '$selection' is out of range"
  fi
  printf '%s\n' "${SERVICE_NAMES[$((selection - 1))]}"
}

choose_action_interactive() {
  local selection=""

  printf 'Select an action:\n' >&2
  printf '  1) start\n' >&2
  printf '  2) stop\n' >&2
  printf '  3) restart\n' >&2
  printf '  4) logs\n' >&2
  printf '> ' >&2
  IFS= read -r selection
  case "$selection" in
    1) printf 'start\n' ;;
    2) printf 'stop\n' ;;
    3) printf 'restart\n' ;;
    4) printf 'logs\n' ;;
    *) die "invalid action selection '$selection'" ;;
  esac
}

prompt_version_interactive() {
  local version=""

  printf 'Version tag [latest]: ' >&2
  IFS= read -r version
  if [ -z "$version" ]; then
    printf 'latest\n'
  else
    printf '%s\n' "$version"
  fi
}

interactive_mode() {
  local service=""
  local action=""
  local version=""

  discover_services
  service="$(choose_service_interactive)"
  action="$(choose_action_interactive)"

  case "$action" in
    start)
      version="$(prompt_version_interactive)"
      start_service "$service" "$version"
      ;;
    stop)
      stop_service "$service"
      ;;
    restart)
      version="$(prompt_version_interactive)"
      restart_service "$service" "$version"
      ;;
    logs)
      logs_service "$service"
      ;;
  esac
}

main() {
  local command="${1:-}"
  local service=""
  local version=""

  if [ "$#" -eq 0 ]; then
    interactive_mode
    return 0
  fi

  if [ "$#" -ge 2 ]; then
    if normalize_service_first_args "$1" "$2" "${@:3}"; then
      set -- "${NORMALIZED_ARGS[@]}"
      command="${1:-}"
    fi
  fi

  case "$command" in
    help|-h|--help)
      usage
      ;;
    services)
      [ "$#" -eq 1 ] || die 'usage: ./deploy.sh services'
      list_services
      ;;
    ports)
      [ "$#" -eq 1 ] || die 'usage: ./deploy.sh ports'
      show_ports
      ;;
    status)
      [ "$#" -eq 1 ] || die 'usage: ./deploy.sh status'
      show_status
      ;;
    start)
      [ "$#" -ge 2 ] || die 'usage: ./deploy.sh start <service> [--version TAG]'
      discover_services
      service="$2"
      version="$(parse_optional_version 'usage: ./deploy.sh start <service> [--version TAG]' "${@:3}")"
      start_service "$service" "$version"
      ;;
    stop)
      [ "$#" -eq 2 ] || die 'usage: ./deploy.sh stop <service>'
      discover_services
      stop_service "$2"
      ;;
    restart)
      [ "$#" -ge 2 ] || die 'usage: ./deploy.sh restart <service> [--version TAG]'
      discover_services
      service="$2"
      version="$(parse_optional_version 'usage: ./deploy.sh restart <service> [--version TAG]' "${@:3}")"
      restart_service "$service" "$version"
      ;;
    logs)
      [ "$#" -eq 2 ] || die 'usage: ./deploy.sh logs <service>'
      discover_services
      logs_service "$2"
      ;;
    start-all)
      version="$(parse_optional_version 'usage: ./deploy.sh start-all [--version TAG]' "${@:2}")"
      start_all_services "$version"
      ;;
    stop-all)
      [ "$#" -eq 1 ] || die 'usage: ./deploy.sh stop-all'
      stop_all_services
      ;;
    prune-images)
      [ "$#" -eq 1 ] || die 'usage: ./deploy.sh prune-images'
      prune_images
      ;;
    clone-prism-b-from-prism-a)
      [ "$#" -eq 1 ] || die 'usage: ./deploy.sh clone-prism-b-from-prism-a'
      clone_prism_b_from_prism_a
      ;;
    *)
      usage >&2
      die "unknown command '$command'"
      ;;
  esac
}

main "$@"
