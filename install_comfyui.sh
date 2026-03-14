#!/usr/bin/env bash
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='[0;31m'; GREEN='[0;32m'; YELLOW='[1;33m'; CYAN='[0;36m'; NC='[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

INSTALL_DIR="/workspace/comfyui"

# ── 1. System dependencies ────────────────────────────────────────────────────
info "Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y git python3 python3-pip python3-venv wget curl ffmpeg     libgl1 libglib2.0-0 libsm6 libxext6 libxrender-dev > /dev/null
success "System dependencies installed."

# ── 2. Clone ComfyUI ──────────────────────────────────────────────────────────
if [ -d "$INSTALL_DIR" ]; then
    warn "ComfyUI directory already exists at $INSTALL_DIR — skipping clone."
else
    info "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$INSTALL_DIR"
    success "ComfyUI cloned."
fi

cd "$INSTALL_DIR"

# ── 3. Python virtual environment ────────────────────────────────────────────
info "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip -q
success "Virtual environment ready."

# ── 4. PyTorch (CUDA 12.1) ───────────────────────────────────────────────────
info "Installing PyTorch with CUDA 12.1 support (this may take a few minutes)..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 -q
success "PyTorch installed."

# ── 5. ComfyUI requirements ───────────────────────────────────────────────────
info "Installing ComfyUI requirements..."
pip install -r requirements.txt -q
success "ComfyUI requirements installed."

# ── 6. Custom nodes ───────────────────────────────────────────────────────────
info "Installing custom nodes..."

CUSTOM_NODES="$INSTALL_DIR/custom_nodes"

clone_or_pull() {
    local repo="$1" dir="$2"
    if [ -d "$dir" ]; then
        warn "$(basename $dir) already exists — pulling latest."
        git -C "$dir" pull -q
    else
        git clone "$repo" "$dir" -q
    fi
}

clone_or_pull "https://github.com/kijai/ComfyUI-WanVideoWrapper"     "$CUSTOM_NODES/ComfyUI-WanVideoWrapper"
clone_or_pull "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite" "$CUSTOM_NODES/ComfyUI-VideoHelperSuite"

pip install -r "$CUSTOM_NODES/ComfyUI-WanVideoWrapper/requirements.txt"   -q
pip install -r "$CUSTOM_NODES/ComfyUI-VideoHelperSuite/requirements.txt"   -q
success "Custom nodes installed."

# ── 7. Create model directories ──────────────────────────────────────────────
info "Creating model directories..."
mkdir -p "$INSTALL_DIR/models/diffusion_models"
mkdir -p "$INSTALL_DIR/models/text_encoders"
mkdir -p "$INSTALL_DIR/models/vae"
mkdir -p "$INSTALL_DIR/models/clip_vision"

# ── 8. HuggingFace token & library ────────────────────────────────────────────
[ -n "${HF_TOKEN:-}" ] || error "HF_TOKEN env var is not set. Export it before running this script (https://huggingface.co/settings/tokens)."

info "Installing huggingface_hub..."
pip install -U huggingface_hub -q

# ── 9. Download models (using Python API) ────────────────────────────────────
info "Downloading Wan2.2 Remix models (very large files — ~30 GB total)..."

hf_download() {
    local repo="$1" hf_path="$2" local_dir="$3" filename="$4"
    local dest="$local_dir/$filename"
    if [ -f "$dest" ]; then
        warn "$filename already exists — skipping download."
    else
        info "Downloading $filename..."
        python -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='$repo',
    filename='$hf_path',
    local_dir='$local_dir',
    token='$HF_TOKEN',
)
"
    fi
}

hf_download "FX-FeiHou/wan2.2-Remix" \
    "NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors" \
    "$INSTALL_DIR/models/diffusion_models" \
    "NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors"

hf_download "FX-FeiHou/wan2.2-Remix" \
    "NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors" \
    "$INSTALL_DIR/models/diffusion_models" \
    "NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors"

hf_download "FX-FeiHou/wan2.2-Remix" \
    "NSFW/nsfw_wan_umt5-xxl_fp8_scaled.safetensors" \
    "$INSTALL_DIR/models/text_encoders" \
    "NSFW/nsfw_wan_umt5-xxl_fp8_scaled.safetensors"

# VAE from the official Wan2.1 repo
VAE_DEST="$INSTALL_DIR/models/vae/wan_2.1_vae.safetensors"
if [ -f "$VAE_DEST" ]; then
    warn "wan_2.1_vae.safetensors already exists — skipping."
else
    info "Downloading Wan2.1 VAE..."
    python -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='Wan-AI/Wan2.1-T2V-14B',
    filename='Wan2.1_VAE.pth',
    local_dir='$INSTALL_DIR/models/vae',
    token='$HF_TOKEN',
)
"
    mv "$INSTALL_DIR/models/vae/Wan2.1_VAE.pth" "$VAE_DEST" 2>/dev/null || true
fi

deactivate

echo ""
success "╔══════════════════════════════════════════════════╗"
success "║  ComfyUI + Wan2.2 Remix installed at:             ║"
success "║  $INSTALL_DIR"
success "║  Run ./launch_comfyui.sh to start the server.     ║"
success "╚══════════════════════════════════════════════════╝"