#!/bin/sh

# 1. Setup loop device with 4096 sector size for internal eMMC userdata (/dev/mmcblk0p54)
if [ -b /dev/mmcblk0p54 ]; then
    echo "=== Setting up loop device for internal eMMC userdata (/dev/mmcblk0p54) ==="
    modprobe loop 2>/dev/null || true
    losetup -d /dev/loop1 2>/dev/null || true
    losetup -P -b 4096 /dev/loop1 /dev/mmcblk0p54 2>/dev/null || true
    mdev -s 2>/dev/null || true
    mkdir -p /dev/disk/by-label /dev/disk/by-uuid
    [ -b /dev/loop1p1 ] && ln -sf /dev/loop1p1 /dev/disk/by-label/pmOS_boot
    [ -b /dev/loop1p2 ] && ln -sf /dev/loop1p2 /dev/disk/by-label/pmOS_root

    # Map actual filesystem UUIDs
    if [ -b /dev/loop1p1 ]; then
        uuid_boot=$(blkid -s UUID -o value /dev/loop1p1 2>/dev/null)
        [ -n "$uuid_boot" ] && ln -sf /dev/loop1p1 "/dev/disk/by-uuid/$uuid_boot"
    fi
    if [ -b /dev/loop1p2 ]; then
        uuid_root=$(blkid -s UUID -o value /dev/loop1p2 2>/dev/null)
        [ -n "$uuid_root" ] && ln -sf /dev/loop1p2 "/dev/disk/by-uuid/$uuid_root"
    fi

    # Map default cmdline UUIDs as well
    ln -sf /dev/loop1p1 /dev/disk/by-uuid/6dd530b7-3ca1-445b-a07b-55c3a8c19c4e 2>/dev/null || true
    ln -sf /dev/loop1p2 /dev/disk/by-uuid/cf6d0d3b-a45d-4ff5-9c36-8561dca8977e 2>/dev/null || true
    ln -sf /dev/loop1p1 /dev/disk/by-uuid/ddb139c7-7b2c-42f7-8e13-534d74675ea3 2>/dev/null || true
    ln -sf /dev/loop1p2 /dev/disk/by-uuid/b32d420e-ce90-4a58-af4e-3168d8916ec2 2>/dev/null || true
fi

if [ -e /dev/disk/by-label/pmOS_root ] || [ -e /dev/disk/by-uuid/cf6d0d3b-a45d-4ff5-9c36-8561dca8977e ] || [ -e /dev/disk/by-uuid/b32d420e-ce90-4a58-af4e-3168d8916ec2 ]; then
    echo "Found pmOS_root on internal eMMC!"
    exit 0
fi

# 2. Otherwise fallback to NBD Netboot over USB
echo "=== NBD Netboot: Waiting for host 172.16.42.2 ==="
for i in $(seq 1 10); do
    if ping -c 1 -W 1 172.16.42.2 >/dev/null 2>&1; then
        echo "Host 172.16.42.2 reachable!"
        break
    fi
    sleep 0.5
done

modprobe nbd 2>/dev/null || true
mdev -s 2>/dev/null || true

for i in $(seq 1 15); do
    if [ -e /dev/nbd0p2 ]; then
        echo "Found /dev/nbd0p2!"
        mkdir -p /dev/disk/by-label /dev/disk/by-uuid
        ln -sf /dev/nbd0p1 /dev/disk/by-label/pmOS_boot
        ln -sf /dev/nbd0p2 /dev/disk/by-label/pmOS_root
        break
    fi
    echo "=== NBD Netboot: Connecting nbd-client (attempt $i) ==="
    nbd-client -b 4096 -p 172.16.42.2 9999 /dev/nbd0 || true
    mdev -s 2>/dev/null || true
    sleep 1
done
