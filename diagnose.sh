#!/usr/bin/env bash
OUT="/workspace/diagnose.txt"
{
    echo "=== Listening ports ==="
    ss -tlnp

    echo ""
    echo "=== VAST_TCP_PORT env vars ==="
    env | grep VAST_TCP_PORT || echo "(none)"

    echo ""
    echo "=== All port-related env vars ==="
    env | grep -i port || echo "(none)"

    echo ""
    echo "=== ComfyUI curl test on 8188 ==="
    curl -s --max-time 3 http://127.0.0.1:8188 | head -1 || echo "(no response)"

    echo ""
    echo "=== ComfyUI curl test on 40592 ==="
    curl -s --max-time 3 http://127.0.0.1:40592 | head -1 || echo "(no response)"

    echo ""
    echo "=== ComfyUI log (last 30 lines) ==="
    tail -30 /workspace/comfyui/comfyui.log 2>/dev/null || echo "(no log)"

    echo ""
    echo "=== ComfyUI PID ==="
    cat /workspace/comfyui/comfyui.pid 2>/dev/null || echo "(no pid file)"
    ps aux | grep "main.py" | grep -v grep || echo "(not running)"
} > "$OUT" 2>&1

echo "Written to $OUT"
cat "$OUT"
