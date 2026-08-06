expect << 'EOF'
spawn bluetoothctl
send "remove 00:1F:E2:D3:B8:8F\r"
send "scan on\r"
sleep 5
send "scan off\r"
send "trust 00:1F:E2:D3:B8:8F\r"
send "pair 00:1F:E2:D3:B8:8F\r"
expect "Pairing successful"
sleep 2
send "quit\r"
expect eof
EOF
