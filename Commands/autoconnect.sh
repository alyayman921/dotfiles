#!/bin/bash

set -e

SERVICE_NAME="ds4-connect"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "[*] Writing service file to ${SERVICE_FILE}..."

sudo tee "$SERVICE_FILE" > /dev/null <<'EOF'
[Unit]
Description=Connect DualShock 4 controller
After=bluetooth.service
Wants=bluetooth.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/bluetoothctl connect 00:1F:E2:D3:B8:8F
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "[*] Enabling service (auto-start on boot)..."
sudo systemctl enable "$SERVICE_NAME"

echo "[*] Starting service now..."
sudo systemctl start "$SERVICE_NAME"

echo ""
echo "[✓] Done! Checking status:"
sudo systemctl status "$SERVICE_NAME" --no-pager
