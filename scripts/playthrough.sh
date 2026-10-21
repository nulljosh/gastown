#!/bin/sh
# Play NYC Survive to the win with no window: scripts/playthrough.sh [max-days]
set -e
cd "$(dirname "$0")/.."
out="${TMPDIR:-/tmp}/nyc-playthrough"
swiftc -O -swift-version 6 -o "$out" Sources/Models/*.swift Sources/Game/Systems/*.swift Sources/Game/World/*.swift \
  Sources/HUD/Theme.swift Sources/Audio/AudioManager.swift scripts/playthrough/*.swift 2>&1 | grep -v warning || true
"$out" "${1:-200}"
