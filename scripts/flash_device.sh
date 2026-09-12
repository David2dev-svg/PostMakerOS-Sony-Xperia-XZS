#!/usr/bin/env bash
# ==============================================================================
# flash_device.sh - Flash PostmarketOS directly to Sony Xperia XZs internal storage
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BOOT_IMG="$PROJECT_ROOT/out/boot.img"
ROOTFS_IMG="$PROJECT_ROOT/out/sony-keyaki-sparse.img"

FASTBOOT_BIN=""
if command -v fastboot >/dev/null 2>&1; then
    FASTBOOT_BIN="fastboot"
elif [ -f "$HOME/Library/Android/sdk/platform-tools/fastboot" ]; then
    FASTBOOT_BIN="$HOME/Library/Android/sdk/platform-tools/fastboot"
fi

if [ -z "$FASTBOOT_BIN" ]; then
    echo "❌ Error: fastboot tool not found in PATH or Android SDK platform-tools."
    exit 1
fi

echo "=========================================================="
echo "🚀 PostmarketOS Standalone Installer for Sony Xperia XZs"
echo "=========================================================="
echo "📦 Boot image:   $BOOT_IMG ($(du -h "$BOOT_IMG" | cut -f1))"
echo "📦 Rootfs image: $ROOTFS_IMG ($(du -h "$ROOTFS_IMG" | cut -f1))"
echo ""

echo "🔍 Waiting for device in Fastboot mode..."
echo "   (If not connected, turn off phone, hold Volume Up and plug in USB)"

while true; do
    FB_DEV=$($FASTBOOT_BIN devices 2>/dev/null | head -n 1 || true)
    if [ -n "$FB_DEV" ]; then
        echo "⚡ Found Fastboot device: $FB_DEV"
        break
    fi
    sleep 1
done

echo ""
echo "Step 1/2: Flashing kernel & initramfs to 'boot' partition..."
$FASTBOOT_BIN flash boot "$BOOT_IMG"
echo "✅ Boot partition flashed successfully!"

echo ""
echo "Step 2/2: Flashing OS root filesystem to 'userdata' partition..."
echo "⏳ This may take 1-2 minutes depending on USB speed..."
$FASTBOOT_BIN flash userdata "$ROOTFS_IMG"
echo "✅ Userdata partition flashed successfully!"

echo ""
echo "🔄 Rebooting device into standalone PostmarketOS..."
$FASTBOOT_BIN reboot
echo "🎉 Done! The phone is now running PostmarketOS standalone from internal memory."
