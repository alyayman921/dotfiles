#!/usr/bin/env bash
set -u

MAC="00:1F:E2:D3:B8:8F"
NAME="Wireless Controller"

while true; do
    # Only act when the DS4 is known to BlueZ (it exists as a device) and not connected
    if bluetoothctl devices 2>/dev/null | grep -qi "$NAME"; then
        state=$(bluetoothctl info "$MAC" 2>/dev/null | grep -E 'Connected:' | awk '{print $2}')
        if [ "$state" != "yes" ]; then
            bluetoothctl connect "$MAC" >/dev/null 2>&1
        fi
    fi
    sleep 2
done
