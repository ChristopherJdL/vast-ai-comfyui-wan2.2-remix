$SSH_KEY = "$env:HOME/.ssh/vast_ai"
$VAST_IP = "174.78.228.101"
$SSH_PORT = 40572

Write-Host "Starting SSH tunnel to Vast.ai (localhost:8188 -> ComfyUI)..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the tunnel." -ForegroundColor Yellow
Write-Host ""

ssh -p $SSH_PORT root@$VAST_IP -L 8188:localhost:8188 -i $SSH_KEY -N
