#!/bin/bash

# Monitor switching script for Hyprland (Lua config, Hyprland 0.55+)
# Usage: ./monitor-switch.sh [0|1|2|3]
# 0 or no argument: Enable both monitors
# 1: Enable only eDP-1 (laptop screen)
# 2: Enable only HDMI-A-1 (external monitor)
# 3: Mirror HDMI-A-1 from eDP-1

# `hyprctl keyword monitor` no longer works with the Lua config parser
# ("keyword can't work with non-legacy parsers. Use eval."). The replacement
# is `hyprctl eval 'hl.monitor({...})'`.
#
# `disabled` is always passed explicitly: a monitor that was disabled before
# stays off unless disabled = false is present (hyprwm/Hyprland#14854).

eval_mon() {
    hyprctl eval "hl.monitor($1)" >/dev/null 2>&1
}

case "$1" in
    0|"")
        # Enable both monitors - eDP-1 on left, HDMI-A-1 positioned to the right
        eval_mon '{ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1, disabled = false }'
        eval_mon '{ output = "HDMI-A-1", mode = "preferred", position = "1920x0", scale = 1, disabled = false }'
        echo "Both monitors enabled (eDP-1 on left, HDMI-A-1 on right)"
        ;;
    1)
        # Enable only eDP-1 (laptop screen)
        eval_mon '{ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1, disabled = false }'
        eval_mon '{ output = "HDMI-A-1", disabled = true }'
        echo "eDP-1 enabled, HDMI-A-1 disabled"
        ;;
    2)
        # Enable only HDMI-A-1 (external monitor)
        eval_mon '{ output = "HDMI-A-1", mode = "preferred", position = "0x0", scale = 1, disabled = false }'
        eval_mon '{ output = "eDP-1", disabled = true }'
        echo "HDMI-A-1 enabled, eDP-1 disabled"
        ;;
    3)
        # Mirror HDMI-A-1 from eDP-1
        eval_mon '{ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1, disabled = false }'
        eval_mon '{ output = "HDMI-A-1", mirror = "eDP-1", disabled = false }'
        echo "HDMI-A-1 mirroring eDP-1"
        ;;
    *)
        echo "Invalid argument. Use 0 (both), 1 (eDP only), 2 (HDMI only), or 3 (mirror)"
        exit 1
        ;;
esac
