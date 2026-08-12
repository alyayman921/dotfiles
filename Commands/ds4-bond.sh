#!/usr/bin/env bash
# DS4 bond snapshot/restore for Arch/bluez 5.87
#   backup:  sudo bash ~/Commands/ds4-bond.sh backup    (run once, after a good pairing)
#   restore: sudo bash ~/Commands/ds4-bond.sh restore   (cron @reboot, or anytime the bond is lost)
set -uo pipefail

REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

DEV_MAC="00:1F:E2:D3:B8:8F"
ADAPTER_MAC="80:91:33:5D:BF:BE"
BACKUP_DIR="/home/aly/Commands/ds4-bond"
SRC="/var/lib/bluetooth/${ADAPTER_MAC}/${DEV_MAC}"

say() { echo "==== $* ===="; }
fail() { echo "ERROR: $*" >&2; exit 1; }

restore_dirs() {
    local src dst
    for src in /var/lib/bluetooth/*/; do
        dst="${src%/}"
        chown root:root "$dst"
        chmod 700 "$dst"
    done
}

cmd_backup() {
    say "backup: $SRC -> $BACKUP_DIR"
    [ -d "$SRC" ] || fail "no bond at $SRC (is the DS4 paired? run 'bluetoothctl info $DEV_MAC')"
    mkdir -p "$BACKUP_DIR"
    cp -a "$SRC"/. "$BACKUP_DIR/"
    chown -R "$(id -un):$(id -gn)" "$BACKUP_DIR"
    echo "--- snapshot contents ---"
    ls -la "$BACKUP_DIR"
    say "backup OK"
}

cmd_restore() {
    say "restore: $BACKUP_DIR -> $SRC"
    [ -d "$BACKUP_DIR" ] || fail "no snapshot at $BACKUP_DIR (run backup once)"
    [ -f "$BACKUP_DIR/info" ] || fail "snapshot has no 'info' file; re-run backup after pairing"

    systemctl stop bluetooth.service
    rm -rf "$SRC"
    mkdir -p "/var/lib/bluetooth/${ADAPTER_MAC}"
    cp -a "$BACKUP_DIR" "$SRC"
    chown -R root:root "$SRC"
    chmod 700 "$SRC"
    chmod 600 "$SRC"/info 2>/dev/null
    restore_dirs
    systemctl start bluetooth.service

    sleep 2
    systemctl is-active bluetooth.service >/dev/null || fail "bluetooth failed to start"
    say "restore OK"
}

case "${1:-}" in
    backup)  cmd_backup ;;
    restore) cmd_restore ;;
    *) echo "usage: $0 {backup|restore}"; exit 1 ;;
esac
