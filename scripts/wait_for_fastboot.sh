#!/bin/bash
echo "Dang cho ket noi Fastboot (den LED xanh duong)..."
for i in $(seq 1 30); do
    DEV=$(fastboot devices | awk '{print $1}')
    if [ -n "$DEV" ]; then
        echo "Da nhan thiet bi Fastboot: $DEV!"
        exit 0
    fi
    sleep 1
done
echo "Timeout cho Fastboot."
exit 1
