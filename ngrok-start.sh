#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ngrok-start.sh  —  Expose ScanPOS to your phone (free plan: 1 tunnel)
#
# How it works:
#   - Only tunnels the Vite dev server (port 5173)
#   - Vite proxies all /api/* calls to Laravel on 127.0.0.1:8000
#   - Your phone only needs the one ngrok URL
#
# Usage: ./ngrok-start.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── 1. Kill any leftover processes ───────────────────────────────────────────
echo "=> Stopping any previous ngrok/vite instance..."
pkill -x ngrok 2>/dev/null || true
kill -9 $(lsof -ti :5173) 2>/dev/null || true
sleep 1

# ── 2. Start Vite with stdin from /dev/null (prevents tty-input suspension) ──
echo "=> Starting Vite dev server (port 5173)..."
cd "$(dirname "$0")/frontend"
nohup npm run dev < /dev/null > /tmp/vite.log 2>&1 &
VITE_PID=$!
cd - > /dev/null
echo -n "=> Waiting for Vite"
for i in {1..20}; do
  if curl -sf http://127.0.0.1:5173/ >/dev/null 2>&1; then
    echo " ready!"
    break
  fi
  echo -n "."
  sleep 1
done

# ── 3. Launch ngrok tunnel for Vite ──────────────────────────────────────────
echo "=> Launching ngrok tunnel (localhost:5173)..."
ngrok http 5173 --log=stdout > /tmp/ngrok-frontend.log 2>&1 &
NGROK_PID=$!

cleanup() {
  echo ""
  echo "=> Stopping ngrok and Vite..."
  kill $NGROK_PID 2>/dev/null || true
  kill $VITE_PID 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ── 3. Poll until the HTTPS tunnel URL appears ───────────────────────────────
echo -n "=> Waiting for tunnel URL"
FRONTEND_URL=""
for i in {1..30}; do
  FRONTEND_URL=$(python3 -c "
import json, urllib.request, sys
try:
    data = json.loads(urllib.request.urlopen('http://127.0.0.1:4040/api/tunnels').read())
    for t in data.get('tunnels', []):
        url = t.get('public_url', '')
        if url.startswith('https'):
            print(url)
            sys.exit(0)
except:
    pass
" 2>/dev/null || true)
  if [[ -n "$FRONTEND_URL" ]]; then
    echo " got it!"
    break
  fi
  echo -n "."
  sleep 1
done

if [[ -z "$FRONTEND_URL" ]]; then
  echo ""
  echo "ERROR: Could not read tunnel URL. ngrok log:"
  tail -10 /tmp/ngrok-frontend.log
  exit 1
fi

# ── 5. Print instructions ─────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
printf "║  Open on phone: %-41s║\n" "$FRONTEND_URL"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  API calls are proxied: phone → ngrok → Vite → Laravel"
echo "  No restart needed — Vite is already running."
echo ""
echo "Press Ctrl+C to stop."
wait $NGROK_PID $VITE_PID
