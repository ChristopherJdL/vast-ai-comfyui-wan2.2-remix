# AGENTS.md

This project automates deployment of an uncensored AI video workflow using ComfyUI on **Vast.ai** GPU instances.

## Context

- The target platform is **Vast.ai** Docker containers (Linux Desktop template, Ubuntu, Supervisor-based — no systemd).
- Authentication is handled by Vast.ai’s built-in Caddy proxy (`ENABLE_AUTH=true`).

- There are **two scripts**:
  1. `install_comfyui.sh` — Install ComfyUI, dependencies, custom nodes (WanVideoWrapper, VideoHelperSuite), and download Wan2.2 Remix model files from HuggingFace.
  2. `launch_comfyui.sh` — Launch ComfyUI in background on `0.0.0.0:8188`, detect VRAM for low-VRAM flags, print public URL.

- Installation target: `/workspace/comfyui` (persists if a volume is attached to `/workspace`).
- PyTorch installed with CUDA 12.1 support (compatible with host CUDA 12.x drivers).
- Model weights require a **HuggingFace token** at install time.



