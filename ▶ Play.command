#!/bin/bash
# Double-click to play Fire Alarm Guy in your default browser.
cd "$(dirname "$0")" || exit 1
echo "🔥 Launching Fire Alarm Guy…"
open "index.html"
echo "Opened in your browser. You can close this window."
sleep 1
