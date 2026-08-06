#!/usr/bin/env bash
set -u

MAC="00:1F:E2:D3:B8:8F"
NAME="Wireless Controller"

echo "==> NOW hold PS + Share until the light bar BLINKS RAPIDLY, then keep holding."
echo "    Scanning for up to ~40s..."

echo "==> Removing stale pairing (if any)"
bluetoothctl remove "$MAC" >/dev/null 2>&1

echo "==> Scanning..."
timeout 45 bluetoothctl --timeout 25 scan on >/dev/null 2>&1 &

for i in $(seq 1 10); do
    if bluetoothctl devices 2>/dev/null | grep -qi "$NAME"; then
        echo "==> Found $NAME at $MAC (attempt $i)"
        break
    fi
    sleep 3
done

if ! bluetoothctl devices 2>/dev/null | grep -qi "$NAME"; then
    echo "==> Not found. Retry: power the controller fully off (hold PS ~10s), then run this again."
    exit 1
fi

echo "==> Pairing..."
bluetoothctl --timeout 25 pair "$MAC" 2>&1 | grep -vE 'U-AC0F12'

echo "==> Trusting..."
bluetoothctl trust "$MAC" >/dev/null 2>&1
echo "trust done"

echo "==> Connecting..."
bluetoothctl connect "$MAC" >/dev/null 2>&1 &
sleep 5
bluetoothctl connect "$MAC" >/dev/null 2>&1

echo "==> State:"
bluetoothctl info "$MAC" 2>/dev/null | grep -E 'Paired:|Bonded:|Trusted:|Connected:' | sed 's/^[[:space:]]*/  /'

if bluetoothctl info "$MAC" 2>/dev/null | grep -q 'Connected: yes'; then
    echo ""
    echo "==> SUCCESS: controller is connected."
    echo "    From now on, the auto-reconnect service will try to connect it"
    echo "    whenever you press PS."
else
    echo ""
    echo "==> Connected: no. Run ds4-pair again while holding PS+Share if needed."
fi
