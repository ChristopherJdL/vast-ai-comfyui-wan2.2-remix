# ComfyUI + Wan2.2 Remix: Image-to-Video Tutorial

## Prerequisites

- Instance running with `./launch_comfyui.sh` executed
- SSH tunnel active (`./tunnel.ps1`)
- Browser open at `http://localhost:8188`

## Step 1: Load the workflow

1. In ComfyUI, click **Load** (top menu bar)
2. Select the file `workflow_i2v.json` (upload it from your local machine, or copy it to the instance under `/workspace/comfyui/`)
3. The workflow nodes will appear on the canvas

## Step 2: Upload your image

1. Find the **Load Image** node on the canvas
2. Click **choose file to upload** and select your source image
3. Recommended: use a clear, well-lit image (the model works best with 720p-ish resolution)

## Step 3: Configure the prompt

1. Find the **CLIP Text Encode** (or positive prompt) node
2. Type a description of the motion you want, e.g.:
   - `"a woman turning her head and smiling"`
   - `"camera slowly zooming in, hair blowing in the wind"`
   - `"the person walks forward"`
3. Keep it short and descriptive — focus on the **motion**, not the scene

## Step 4: Choose the model variant

The workflow may reference two diffusion models:

| Model | Use when |
|-------|----------|
| `Wan2.2_Remix_..._high_lighting_v2.0.safetensors` | Source image is well-lit (daylight, studio) |
| `Wan2.2_Remix_..._low_lighting_v2.0.safetensors` | Source image is dark (night, moody) |

In the **Load Diffusion Model** node, select the appropriate one.

## Step 5: Adjust settings (optional)

| Setting | Recommended | Notes |
|---------|-------------|-------|
| Steps | 20-30 | More steps = better quality, slower |
| CFG | 6-8 | How closely to follow the prompt |
| Frames | 16-32 | Number of video frames |
| Width/Height | 832x480 or 480x832 | Match your image orientation |

## Step 6: Generate

1. Click **Queue Prompt** (top right corner)
2. Wait — on an A100, a 16-frame video takes ~1-2 minutes
3. The output appears in the **Video Preview** node
4. Right-click the preview to save/download the video

## Tips

- **Short prompts work better** — describe motion, not appearance
- **Match lighting model to your image** — wrong lighting model gives worse results
- If you get OOM errors, reduce resolution or frame count
- The text encoder (`nsfw_wan_umt5-xxl_fp8_scaled`) is fp8 quantized to save VRAM

## Copying the workflow to the instance

From your Mac:
```bash
scp -P 40572 -i ~/.ssh/vast_ai workflow_i2v.json root@174.78.228.101:/workspace/comfyui/
```

Or drag-and-drop the `workflow_i2v.json` file directly into the ComfyUI browser window.
