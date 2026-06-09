#!/bin/sh
set -eu

# Both backend and GUI read/write sidecar files relative to the config dir.
# Force both to use /data/ so they stay in sync.
export DPMP_CONFIG=/data/config_v2.json
export DPMP_CONFIG_PATH=/data/config_v2.json

mkdir -p /data

if [ ! -f "$DPMP_CONFIG" ]; then
  echo "ERROR: config not found at $DPMP_CONFIG" >&2
  exit 1
fi

# Ensure config exists at /data/ (it should already)
cp "$DPMP_CONFIG" /data/config_v2.json 2>/dev/null || true

RUN_LOG="/data/dpmpv2_run.log"
GUI_LOG="/data/dpmpv2_gui.log"
: > "$RUN_LOG"
: > "$GUI_LOG"

# Start DPMP backend (reads DPMP_CONFIG)
python -u /app/dpmp/dpmpv2.py >> "$RUN_LOG" 2>&1 &
DPMP_PID=$!

# Start NiceGUI dashboard (reads DPMP_CONFIG_PATH)
python -u /app/gui_nice/app.py >> "$GUI_LOG" 2>&1 &
GUI_PID=$!

trap "kill -TERM $DPMP_PID $GUI_PID 2>/dev/null; wait $DPMP_PID $GUI_PID 2>/dev/null; exit 0" TERM INT

n=0
while true; do
  if ! kill -0 "$DPMP_PID" 2>/dev/null; then
    wait "$DPMP_PID" 2>/dev/null
    DPMP_EXIT=$?
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) dpmpv2 exited with code $DPMP_EXIT" >&2
    exit 1
  fi
  if ! kill -0 "$GUI_PID" 2>/dev/null; then
    wait "$GUI_PID" 2>/dev/null
    GUI_EXIT=$?
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) nicegui exited with code $GUI_EXIT" >&2
    exit 1
  fi
  n=$((n + 1))
  if [ "$n" -ge 60 ]; then
    n=0
  fi
  sleep 1
done
