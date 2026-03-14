#!/usr/bin/env bash
set -euo pipefail

RED='[0;31m'; GREEN='[0;32m'; YELLOW='[1;33m'; CYAN='[0;36m'; BOLD='[1m'; NC='[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

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
        warn "ComfyUI is already running (PID $OLD_PID). Restarting..."
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
    info "Detected GPU VRAM: ${VRAM_GB} GB"
    if [ "$VRAM_GB" -le 16 ]; then
        EXTRA_FLAGS="--lowvram --disable-smart-memory"
        warn "Low VRAM detected — adding flags: $EXTRA_FLAGS"
    fi
else
    warn "nvidia-smi not found — running without GPU optimisation flags."
fi

# ── Launch ComfyUI ────────────────────────────────────────────────────────────
info "Starting ComfyUI in background..."
cd "$INSTALL_DIR"
source venv/bin/activate

nohup python main.py     --listen 0.0.0.0     --port "$COMFYUI_PORT"     $EXTRA_FLAGS     > "$LOG_FILE" 2>&1 &

COMFY_PID=$!
echo "$COMFY_PID" > "$PID_FILE"
success "ComfyUI started (PID $COMFY_PID). Log: $LOG_FILE"

# ── Wait for ComfyUI to become ready ─────────────────────────────────────────
info "Waiting for ComfyUI to become ready..."
MAX_WAIT=60
ELAPSED=0
until curl -s "http://127.0.0.1:${COMFYUI_PORT}" > /dev/null 2>&1; do
    sleep 2
    ELAPSED=$(( ELAPSED + 2 ))
    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        warn "ComfyUI did not respond within ${MAX_WAIT}s. Check logs: tail -f $LOG_FILE"
        break
    fi
    echo -n "."
done
echo ""

# ── Resolve public IP ─────────────────────────────────────────────────────────
info "Resolving access URL..."

PUBLIC_IP=""
for service in "https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com"; do
    PUBLIC_IP=$(curl -s --max-time 5 "$service" 2>/dev/null || true)
    [ -n "$PUBLIC_IP" ] && break
done

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║              ComfyUI is UP and RUNNING                   ║${NC}"
echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}${GREEN}║${NC}  Open in browser: ${CYAN}http://${PUBLIC_IP:-<unknown>}:${COMFYUI_PORT}${NC}"
echo -e "${BOLD}${GREEN}║${NC}  Local          : ${CYAN}http://127.0.0.1:${COMFYUI_PORT}${NC}"
echo -e "${BOLD}${GREEN}║${NC}  PID file       : ${PID_FILE}"
echo -e "${BOLD}${GREEN}║${NC}  Logs           : tail -f ${LOG_FILE}"
echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}${GREEN}║${NC}  To stop:    kill \$(cat ${PID_FILE})                  "
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""