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

# ── 8. HuggingFace token & CLI ───────────────────────────────────────────────
[ -n "${HF_TOKEN:-}" ] || error "HF_TOKEN env var is not set. Export it before running this script (https://huggingface.co/settings/tokens)."

info "Installing huggingface_hub CLI..."
pip install -U "huggingface_hub[cli]" -q

# ── 9. Download models ────────────────────────────────────────────────────────
info "Downloading Wan2.2 Remix models (very large files — ~30 GB total)..."

HF_REPO="FX-FeiHou/wan2.2-Remix"

download_model() {
    local filename="$1" subdir="$2" hf_path="$3"
    local dest="$INSTALL_DIR/models/$subdir/$filename"
    if [ -f "$dest" ]; then
        warn "$filename already exists — skipping download."
    else
        info "Downloading $filename..."
        python -m huggingface_hub download "$HF_REPO" "$hf_path"             --local-dir "$INSTALL_DIR/models/$subdir"             --local-dir-use-symlinks False             --token "$HF_TOKEN"
    fi
}

download_model     "Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors"     "diffusion_models"     "NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors"

download_model     "Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors"     "diffusion_models"     "NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors"

download_model     "nsfw_wan_umt5-xxl_fp8_scaled.safetensors"     "text_encoders"     "NSFW/nsfw_wan_umt5-xxl_fp8_scaled.safetensors"

# VAE from the official Wan2.1 repo
VAE_DEST="$INSTALL_DIR/models/vae/wan_2.1_vae.safetensors"
if [ -f "$VAE_DEST" ]; then
    warn "wan_2.1_vae.safetensors already exists — skipping."
else
    info "Downloading Wan2.1 VAE..."
    python -m huggingface_hub download Wan-AI/Wan2.1-T2V-14B         "Wan2.1_VAE.pth"         --local-dir "$INSTALL_DIR/models/vae"         --local-dir-use-symlinks False         --token "$HF_TOKEN"
    mv "$INSTALL_DIR/models/vae/Wan2.1_VAE.pth" "$VAE_DEST" 2>/dev/null || true
fi

deactivate

echo ""
success "╔══════════════════════════════════════════════════╗"
success "║  ComfyUI + Wan2.2 Remix installed at:             ║"
success "║  $INSTALL_DIR"
success "║  Run ./launch_comfyui.sh to start the server.     ║"
success "╚══════════════════════════════════════════════════╝"