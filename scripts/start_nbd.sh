#!/usr/bin/env bash
# ==============================================================================
# start_nbd.sh - Launch qemu-nbd server to serve rootfs over USB network
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RAW_IMAGE="$PROJECT_ROOT/out/sony-keyaki.raw"

if [ ! -f "$RAW_IMAGE" ]; then
    echo "❌ Error: Rootfs raw image not found at $RAW_IMAGE"
    exit 1
fi

EXISTING_PID=$(pgrep -f "qemu-nbd.*$RAW_IMAGE" || true)
if [ -n "$EXISTING_PID" ]; then
    echo "ℹ️  qemu-nbd is already running (PID: $EXISTING_PID) serving $RAW_IMAGE"
    exit 0
fi

echo "🚀 Starting qemu-nbd on port 9999..."
nohup qemu-nbd -p 9999 -b 0.0.0.0 -t -e 8 -f raw "$RAW_IMAGE" > /tmp/qemu-nbd.log 2>&1 &
sleep 1

NEW_PID=$(pgrep -f "qemu-nbd.*$RAW_IMAGE" || true)
if [ -n "$NEW_PID" ]; then
    echo "✅ qemu-nbd running successfully (PID: $NEW_PID) on 0.0.0.0:9999"
else
    echo "❌ Failed to start qemu-nbd. Check /tmp/qemu-nbd.log"
    exit 1
fi
