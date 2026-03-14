# Quick GUI Fixes (ComfyUI)

Use these adjustments in the GUI to reduce blur/noise and control duration.

## 1) Duration (frames)
The `WanImageToVideo.length` field is **frames**.

Examples:
- 6s @ 12fps -> 72
- 8s @ 12fps -> 96
- 10s @ 12fps -> 120

Recommendation for quality + manageability:
- `length`: 72 to 96 (per clip)

## 2) Quality / Sharpness
These changes reduce noise and improve clarity:

- `Steps` (KJNodes): **24 to 30** (was 8)
- `KSampler cfg`: **5 to 7** (was 1.0)

## 3) Resolution
Higher resolution improves clarity but costs more VRAM/time.

- Preferred: `1920x1080` if stable
- Fallback: `1600x900` or `1280x720`

## 4) Suggested Baseline Settings
For a good first pass:
- `length`: 72 (6s @ 12fps)
- `Steps`: 24
- `cfg`: 6
- `resolution`: 1600x900 or 1920x1080

## 5) Long Form Strategy
2 minutes in one shot is not practical. Instead:
- Generate multiple 6 to 8 second clips
- Stitch them with crossfades

## Values That Worked Before (from your screenshot)
- `length`: 33
- `Steps`: 8
- `cfg`: 1.0
- `resolution`: 720x1280
- `sampler`: euler
- `scheduler`: simple

## Noise/Blur Quick Notes
- Increase Steps and CFG first.
- Use a higher res (try 1600x900 or 1920x1080).
- Consider a sharpen or detail pass after the video is generated.
