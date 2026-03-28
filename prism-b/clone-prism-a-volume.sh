#!/usr/bin/env bash
set -euo pipefail

# Clone Prism A Postgres volume into Prism B Postgres volume.
#
# Optional overrides:
#   SOURCE_PROJECT (default: prism-a)
#   TARGET_PROJECT (default: prism-b)
#   VOLUME_KEY     (default: prism_postgres_data)
#   SOURCE_VOLUME  (explicit source volume name)
#   TARGET_VOLUME  (explicit target volume name)

SOURCE_PROJECT="${SOURCE_PROJECT:-prism-a}"
TARGET_PROJECT="${TARGET_PROJECT:-prism-b}"
VOLUME_KEY="${VOLUME_KEY:-prism_postgres_data}"
SOURCE_VOLUME="${SOURCE_VOLUME:-}"
TARGET_VOLUME="${TARGET_VOLUME:-}"

resolve_volume() {
  local project="$1"
  local key="$2"
  local by_label=""
  local fallback="${project}_${key}"

  by_label="$(docker volume ls -q \
    --filter "label=com.docker.compose.project=${project}" \
    --filter "label=com.docker.compose.volume=${key}" | head -n 1)"

  if [ -n "${by_label}" ]; then
    printf '%s\n' "${by_label}"
    return 0
  fi

  if docker volume inspect "${fallback}" >/dev/null 2>&1; then
    printf '%s\n' "${fallback}"
    return 0
  fi

  return 1
}

if docker ps -q --filter "label=com.docker.compose.project=${TARGET_PROJECT}" | grep -q .; then
  echo "error: ${TARGET_PROJECT} containers are running. Stop them first (./deploy.sh stop ${TARGET_PROJECT})." >&2
  exit 1
fi

if [ -z "${SOURCE_VOLUME}" ]; then
  if ! SOURCE_VOLUME="$(resolve_volume "${SOURCE_PROJECT}" "${VOLUME_KEY}")"; then
    echo "error: source volume for ${SOURCE_PROJECT}/${VOLUME_KEY} was not found." >&2
    echo "hint: start ${SOURCE_PROJECT} once so Docker creates the volume." >&2
    exit 1
  fi
fi

if [ -z "${TARGET_VOLUME}" ]; then
  if ! TARGET_VOLUME="$(resolve_volume "${TARGET_PROJECT}" "${VOLUME_KEY}")"; then
    TARGET_VOLUME="${TARGET_PROJECT}_${VOLUME_KEY}"
    docker volume create "${TARGET_VOLUME}" >/dev/null
  fi
fi

if [ "${SOURCE_VOLUME}" = "${TARGET_VOLUME}" ]; then
  echo "error: source and target volume are the same (${SOURCE_VOLUME})." >&2
  exit 1
fi

echo "Cloning volume data:"
echo "  from: ${SOURCE_VOLUME}"
echo "  to:   ${TARGET_VOLUME}"

docker run --rm \
  -v "${SOURCE_VOLUME}:/from:ro" \
  -v "${TARGET_VOLUME}:/to" \
  alpine:3.20 sh -euc '
    find /to -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp -a /from/. /to/
  '

echo "Done."
