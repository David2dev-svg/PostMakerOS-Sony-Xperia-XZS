#!/usr/bin/env bash
# ==============================================================================
# flash_boot.sh - Utility to flash boot.img to Sony Xperia XZs (SO-03J / keyaki)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BOOT_IMG="$PROJECT_ROOT/out/boot.img"

if [ ! -f "$BOOT_IMG" ]; then
    echo "❌ Error: boot.img not found at $BOOT_IMG"
    exit 1
fi

echo "📦 Target boot image: $BOOT_IMG ($(du -h "$BOOT_IMG" | cut -f1))"

# Check Fastboot first
echo "🔍 Checking for Fastboot device..."
FASTBOOT_BIN=""
if command -v fastboot >/dev/null 2>&1; then
    FASTBOOT_BIN="fastboot"
elif [ -f "$HOME/Library/Android/sdk/platform-tools/fastboot" ]; then
    FASTBOOT_BIN="$HOME/Library/Android/sdk/platform-tools/fastboot"
fi

if [ -n "$FASTBOOT_BIN" ]; then
    FB_DEV=$($FASTBOOT_BIN devices 2>/dev/null | head -n 1 || true)
    if [ -n "$FB_DEV" ]; then
        echo "⚡ Found Fastboot device: $FB_DEV"
        echo "🚀 Flashing boot partition..."
        $FASTBOOT_BIN flash boot "$BOOT_IMG"
        echo "🔄 Rebooting device..."
        $FASTBOOT_BIN reboot
        echo "✅ Flashing complete and device rebooted!"
        exit 0
    fi
fi

# Check SSH (172.16.42.1)
echo "🔍 Checking for running Linux system via SSH (172.16.42.1)..."
if ping -c 1 -W 500 172.16.42.1 >/dev/null 2>&1; then
    echo "🌐 Phone is reachable via USB network."
    echo "🚀 Streaming boot.img to /dev/mmcblk0p30..."
    cat "$BOOT_IMG" | ssh -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no user@172.16.42.1 \
        'echo 1412 | sudo -S dd of=/dev/mmcblk0p30 bs=4M conv=fsync'
    echo "🔄 Triggering reboot on phone..."
    ssh -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no user@172.16.42.1 \
        'echo user | sudo -S reboot' || true
    echo "✅ Flashing complete and device rebooted!"
    exit 0
fi

echo "⚠️  No device detected in Fastboot or via SSH."
echo "👉 To flash via Fastboot:"
echo "   1. Turn off phone completely."
echo "   2. Hold Volume Up and plug in USB cable (Blue LED will turn on)."
echo "   3. Run this script again."
exit 1
