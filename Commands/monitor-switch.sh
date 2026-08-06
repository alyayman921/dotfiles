#!/bin/bash

# Monitor switching script for Hyprland
# Usage: ./monitor-switch.sh [0|1|2]
# 0 or no argument: Enable both monitors
# 1: Enable only eDP-1 (laptop screen)
# 2: Enable only HDMI-A-1 (external monitor)

case "$1" in
    0|"")
        # Enable both monitors - eDP-1 on left, HDMI-A-1 auto-positioned to the right
        hyprctl keyword monitor "eDP-1,preferred,0x0,1"
        hyprctl keyword monitor "HDMI-A-1,preferred,1920x0,1"
        echo "Both monitors enabled (eDP-1 on left, HDMI-A-1 on right)"
        ;;
    1)
        # Enable only eDP-1 (laptop screen)
        hyprctl keyword monitor "eDP-1,preferred,0x0,1"
        hyprctl keyword monitor "HDMI-A-1,disable"
        echo "eDP-1 enabled, HDMI-A-1 disabled"
        ;;
    2)
        # Enable only HDMI-A-1 (external monitor)
        hyprctl keyword monitor "HDMI-A-1,preferred,0x0,1"
        hyprctl keyword monitor "eDP-1,disable"
        echo "HDMI-A-1 enabled, eDP-1 disabled"
        ;;
    3)
        # Enable only HDMI-A-1 (external monitor)
        hyprctl keyword monitor "eDP-1,preferred,0x0,1"
        hyprctl keyword monitor "HDMI-A-1,highres,auto,1,mirror,eDP-1"
        echo "HDMI-A-1 enabled, eDP-1 disabled"
        ;;
    *)
        echo "Invalid argument. Use 0 (both), 1 (eDP only), or 2 (HDMI only)"
        exit 1
        ;;
esac
