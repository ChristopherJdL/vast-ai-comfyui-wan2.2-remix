#!/usr/bin/env bash
set -euo pipefail

RED='[0;31m'; GREEN='[0;32m'; YELLOW='[1;33m'; CYAN='[0;36m'; NC='[0m'
log()   { echo -e "$*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

INSTALL_DIR="/workspace/comfyui"
COMFYUI_PORT=8188
LOG_FILE="${INSTALL_DIR}/comfyui.log"
PID_FILE="${INSTALL_DIR}/comfyui.pid"

# ── Guard: ComfyUI directory ──────────────────────────────────────────────────
[ -d "$INSTALL_DIR" ] || error "ComfyUI not found at $INSTALL_DIR. Run install_comfyui.sh first."
[ -f "$INSTALL_DIR/main.py" ] || error "main.py not found. Installation may be incomplete."

# ── Stop existing instance ────────────────────────────────────────────────────
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        log "Restarting ComfyUI (PID $OLD_PID)..."
        kill "$OLD_PID"
        sleep 2
    fi
    rm -f "$PID_FILE"
fi

# ── Detect VRAM and set flags ─────────────────────────────────────────────────
EXTRA_FLAGS=""
if command -v nvidia-smi &>/dev/null; then
    VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1 | tr -d ' ')
    VRAM_GB=$(( VRAM_MB / 1024 ))
    if [ "$VRAM_GB" -le 16 ]; then
        EXTRA_FLAGS="--lowvram --disable-smart-memory"
        warn "Low VRAM detected — using $EXTRA_FLAGS"
    fi
fi

# ── Launch ComfyUI ────────────────────────────────────────────────────────────
cd "$INSTALL_DIR"
source venv/bin/activate

nohup python main.py     --listen 0.0.0.0     --port "$COMFYUI_PORT"     $EXTRA_FLAGS     > "$LOG_FILE" 2>&1 &

COMFY_PID=$!
echo "$COMFY_PID" > "$PID_FILE"
log "ComfyUI started (PID $COMFY_PID). Log: $LOG_FILE"

# ── Wait for ComfyUI to become ready ─────────────────────────────────────────
MAX_WAIT=60
ELAPSED=0
until curl -s "http://127.0.0.1:${COMFYUI_PORT}" > /dev/null 2>&1; do
    sleep 2
    ELAPSED=$(( ELAPSED + 2 ))
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        warn "ComfyUI not responding after ${MAX_WAIT}s. Check logs: tail -f $LOG_FILE"
        break
    fi
done

# ── Resolve public IP ─────────────────────────────────────────────────────────
PUBLIC_IP=""
for service in "https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com"; do
    PUBLIC_IP=$(curl -s --max-time 5 "$service" 2>/dev/null || true)
    [ -n "$PUBLIC_IP" ] && break
done

log "Open: http://${PUBLIC_IP:-<unknown>}:${COMFYUI_PORT}"
log "Local: http://127.0.0.1:${COMFYUI_PORT}"
log "Stop:  kill \$(cat ${PID_FILE})"
