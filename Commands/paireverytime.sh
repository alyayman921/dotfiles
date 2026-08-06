sudo tee /etc/systemd/system/ds4-watch.service << 'EOF'
[Unit]
Description=DualShock 4 Auto-Reconnect
After=bluetooth.service
Wants=bluetooth.service

[Service]
Type=simple
Restart=always
RestartSec=10
ExecStart=/bin/bash -c '\
while true; do \
  if bluetoothctl info 00:1F:E2:D3:B8:8F | grep -q "Connected: yes"; then \
    sleep 30; \
    continue; \
  fi; \
  bluetoothctl remove 00:1F:E2:D3:B8:8F; \
  sleep 2; \
  bluetoothctl scan on; \
  sleep 5; \
  bluetoothctl scan off; \
  sleep 1; \
  bluetoothctl trust 00:1F:E2:D3:B8:8F; \
  bluetoothctl pair 00:1F:E2:D3:B8:8F; \
  sleep 5; \
  bluetoothctl connect 00:1F:E2:D3:B8:8F; \
  sleep 15; \
done'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart ds4-watch.service
