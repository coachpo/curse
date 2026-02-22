#!/bin/sh
# Beacon Spear backend entrypoint
# Runs migrations, starts the delivery worker in the background,
# then starts gunicorn in the foreground.
#
# Both processes share the same container so SQLite WAL mode works
# correctly (shared -shm memory region).

set -eu

echo "[entrypoint] Running migrations..."
python manage.py migrate --noinput

echo "[entrypoint] Starting delivery worker (background)..."
python manage.py deliveries_worker &
WORKER_PID=$!

echo "[entrypoint] Starting gunicorn..."
gunicorn beacon_spear.wsgi:application \
    --bind 0.0.0.0:8100 \
    --workers "${WEB_CONCURRENCY:-2}" \
    --access-logfile - \
    --error-logfile - &
GUNICORN_PID=$!

shutdown() {
    kill "$WORKER_PID" "$GUNICORN_PID" 2>/dev/null || true
    wait "$WORKER_PID" 2>/dev/null || true
    wait "$GUNICORN_PID" 2>/dev/null || true
}

trap 'shutdown; exit 0' INT TERM

while :; do
    if ! kill -0 "$WORKER_PID" 2>/dev/null; then
        echo "[entrypoint] Delivery worker exited unexpectedly; stopping gunicorn."
        kill "$GUNICORN_PID" 2>/dev/null || true
        wait "$GUNICORN_PID" 2>/dev/null || true
        wait "$WORKER_PID" 2>/dev/null || true
        exit 1
    fi

    if ! kill -0 "$GUNICORN_PID" 2>/dev/null; then
        wait "$GUNICORN_PID" || GUNICORN_EXIT=$?
        GUNICORN_EXIT=${GUNICORN_EXIT:-0}
        echo "[entrypoint] Gunicorn exited (code: $GUNICORN_EXIT); stopping delivery worker."
        kill "$WORKER_PID" 2>/dev/null || true
        wait "$WORKER_PID" 2>/dev/null || true
        exit "$GUNICORN_EXIT"
    fi

    sleep 2
done
