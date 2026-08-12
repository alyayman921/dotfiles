#!/usr/bin/env bash
# DS4 (DualShock 4 ZCT2) auto-reconnect — definitive fix for Arch/bluez 5.87
# Run once:  sudo bash /tmp/ds4-fix.sh
set -uo pipefail

MAC="00:1F:E2:D3:B8:8F"
ALY_UID="1000"
ALY_RT="/run/user/$ALY_UID"

say(){ echo; echo "==== $* ===="; }
bail(){ echo "ERROR: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || bail "run as root: sudo bash $0"

say "1/8  Bluetooth config (/etc/bluetooth/input.conf)"
mkdir -p /etc/bluetooth
cp -a /etc/bluetooth/input.conf /etc/bluetooth/input.conf.bak.$(date +%s) 2>/dev/null
printf '[General]\nUserspaceHID=false\nClassicBondedOnly=false\n' > /etc/bluetooth/input.conf
cat /etc/bluetooth/input.conf

say "2/8  main.conf: enable bluez-native HID reconnect"
cp -a /etc/bluetooth/main.conf /etc/bluetooth/main.conf.bak.$(date +%s) 2>/dev/null
if grep -q '^ReconnectUUIDs=' /etc/bluetooth/main.conf; then
    sed -i 's|^ReconnectUUIDs=.*|ReconnectUUIDs=00001124-0000-1000-8000-00805f9b34fb,0000111f-0000-1000-8000-00805f9b34fb|' /etc/bluetooth/main.conf
else
    sed -i 's|^#ReconnectUUIDs=.*|ReconnectUUIDs=00001124-0000-1000-8000-00805f9b34fb,0000111f-0000-1000-8000-00805f9b34fb|' /etc/bluetooth/main.conf
fi
grep -E '^ReconnectUUIDs|^ReconnectAttempts|^AutoEnable' /etc/bluetooth/main.conf

say "3/8  kernel hidp module"
printf 'hidp\n' > /etc/modules-load.d/hidp.conf
modprobe hidp 2>/dev/null || true
lsmod | grep -q '^hidp' && echo "hidp loaded OK" || echo "WARN: hidp not loaded"

say "4/8  headless auto-accept agent (replaces blueman's agent)"
cat > /usr/local/bin/bt-agent-ds4.py <<'PYEOF'
#!/usr/bin/env python3
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

AGENT_PATH = "/org/bluez/agent/autoaccept"
AGENT_CAP = "KeyboardDisplay"


class AutoAcceptAgent(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, AGENT_PATH)
        self.bus = bus

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Release(self):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Cancel(self):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        return "0000"

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        return dbus.UInt32(0)

    @dbus.service.method("org.bluez.Agent1", in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        pass


def register(bus):
    try:
        agm = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"), "org.bluez.AgentManager1")
        try:
            agm.UnregisterAgent(AGENT_PATH)
        except dbus.DBusException:
            pass
        agm.RegisterAgent(AGENT_PATH, AGENT_CAP)
        agm.RequestDefaultAgent(AGENT_PATH)
    except dbus.DBusException as e:
        print(f"agent register failed: {e}", flush=True)


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    AutoAcceptAgent(bus)
    register(bus)
    GLib.timeout_add_seconds(15, lambda: (register(bus), True)[1])
    print("bt-agent-ds4 running", flush=True)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
PYEOF
chmod +x /usr/local/bin/bt-agent-ds4.py

cat > /etc/systemd/system/bt-agent.service <<'UNIT'
[Unit]
Description=Bluetooth auto-accept agent (DS4)
After=bluetooth.service
PartOf=bluetooth.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/bt-agent-ds4.py
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now bt-agent.service 2>&1
sleep 1
systemctl is-active bt-agent.service

say "5/8  disable blueman completely"
systemctl disable blueman-mechanism.service 2>/dev/null || true
systemctl mask blueman-mechanism.service 2>/dev/null || true
pkill -9 -f blueman 2>/dev/null || true
rm -f /etc/xdg/autostart/blueman.desktop
if [ -d "$ALY_RT" ]; then
    sudo -u "#$ALY_UID" XDG_RUNTIME_DIR="$ALY_RT" systemctl --user mask blueman-applet.service 2>/dev/null || true
    sudo -u "#$ALY_UID" XDG_RUNTIME_DIR="$ALY_RT" systemctl --user mask blueman-manager.service 2>/dev/null || true
    sudo -u "#$ALY_UID" XDG_RUNTIME_DIR="$ALY_RT" systemctl --user mask app-blueman@autostart.service 2>/dev/null || true
fi
echo "blueman disabled."

say "6/8  restart bluetooth + load agent"
systemctl restart bluetooth.service
systemctl restart bt-agent.service 2>/dev/null || true
sleep 3
systemctl is-active bluetooth.service
systemctl is-active bt-agent.service

say "7/8  trust the DS4 so incoming reconnects are auto-authorized"
for i in $(seq 1 10); do
    if bluetoothctl info "$MAC" >/dev/null 2>&1; then break; fi
    sleep 1
done
bluetoothctl trust "$MAC" 2>&1 || true
sleep 1
bluetoothctl info "$MAC" 2>/dev/null | grep -E 'Paired:|Bonded:|Trusted:|Connected:|Alias' || echo "WARN: device not known yet"

say "8/8  state verification"
echo "--- storage (bond should be here) ---"
ls -la /var/lib/bluetooth/*/ 2>/dev/null | head -30
echo
for d in /var/lib/bluetooth/*/00:1F:E2:D3:B8:8F; do
    [ -d "$d" ] && echo "--- $d/info ---" && cat "$d/info" 2>/dev/null
done
echo
echo "--- running services ---"
systemctl is-active bluetooth.service bt-agent.service ds4drv.service 2>/dev/null
echo
echo "--- done. ---"
echo
echo "NEXT STEPS"
echo "  1. Turn the DS4 OFF (hold PS ~10s)."
echo "  2. Press PS once. It should reconnect on its own (blinking light stops, white light solid)."
echo "  3. Verify: bluetoothctl info $MAC  ->  Connected: yes"
echo "  4. Reboot once to confirm it survives: after login, press PS and it must connect."
echo
echo "  If it still fails after reboot, run this and paste the output:"
echo "     sudo journalctl -u bluetooth -b | grep -iE '00:1f:e2|reject|crash|dumped' | tail -40"
