#!/usr/bin/env bash
set -euo pipefail

PID_FILE="/workspace/comfyui/comfyui.pid"

if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Stopping ComfyUI (PID $OLD_PID)..."
        kill "$OLD_PID"
        sleep 2
    fi
    rm -f "$PID_FILE"
fi

exec "$(dirname "$0")/launch_comfyui.sh"
