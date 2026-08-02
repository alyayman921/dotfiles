#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

confirm() {
    read -rp "Continue? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

install_sublime() {
    local src_root="$HOME/.config"
    local sublime_dir=""
    for d in "sublime-text" "sublime-text-4" "sublime-text-3"; do
        if [[ -d "$src_root/$d" ]]; then
            sublime_dir="$d"
            break
        fi
    done
    sublime_dir="${sublime_dir:-sublime-text}"

    local src="$REPO_DIR/sublime-text/Packages/User"
    local dest="$src_root/$sublime_dir/Packages/User"
    if [[ ! -d "$src" ]]; then
        echo "error: no backed-up config found at $src" >&2
        return 1
    fi

    echo "files to install:"
    find "$src" -maxdepth 1 -type f -printf "  %f\n" | sort
    echo ""
    confirm || { echo "aborted"; return 0; }

    if pgrep -x sublime_text >/dev/null 2>&1; then
        echo "error: sublime_text is running. quit it first." >&2
        return 1
    fi

    mkdir -p "$src_root/$sublime_dir/Packages"
    if [[ -d "$dest" ]] && [[ -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
        local bak="$dest.bak.$(date +%Y%m%d-%H%M%S)"
        mv "$dest" "$bak"
        echo "moved existing config to $bak"
    fi
    cp -a "$src" "$dest"
    echo "installed $src -> $dest"
}

install_bspwm() {
    local src="$REPO_DIR/bspwm"
    local dest="$HOME/.config/bspwm"
    if [[ ! -d "$src" ]]; then
        echo "error: no backed-up config found at $src" >&2
        return 1
    fi

    echo "files to install:"
    find "$src" -type f -printf "  %P\n" | sort
    echo ""
    confirm || { echo "aborted"; return 0; }

    mkdir -p "$dest"
    cp -a "$src/." "$dest/"
    echo "installed files -> $dest"
    echo "run 'bspc wm -r' or restart bspwm to apply changes"
}

install_hypr() {
    local src="$REPO_DIR/hypr"
    local dest="$HOME/.config/hypr"
    if [[ ! -d "$src" ]]; then
        echo "error: no backed-up config found at $src" >&2
        return 1
    fi

    echo "files to install:"
    find "$src" -maxdepth 1 -type f -printf "  %f\n" | sort
    echo ""
    confirm || { echo "aborted"; return 0; }

    mkdir -p "$dest"
    while IFS= read -r -d '' f; do
        cp -a "$f" "$dest/"
    done < <(find "$src" -maxdepth 1 -type f -print0)
    echo "installed files -> $dest"
    echo "run 'hyprctl reload' to apply changes"
}

install_nvim() {
    local src="$REPO_DIR/nvim"
    local dest="$HOME/.config/nvim"
    if [[ ! -d "$src" ]]; then
        echo "error: no backed-up config found at $src" >&2
        return 1
    fi

    echo "files to install:"
    find "$src" -type f -printf "  %P\n" | sort
    echo ""
    confirm || { echo "aborted"; return 0; }

    if [[ -d "$dest" ]] && [[ -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
        local bak="$dest.bak.$(date +%Y%m%d-%H%M%S)"
        mv "$dest" "$bak"
        echo "moved existing config to $bak"
    fi
    mkdir -p "$dest"
    cp -a "$src/." "$dest/"
    echo "installed files -> $dest"
}

echo "What do you want to install? (default: all)"
echo "  1) sublime-text   - Sublime Text settings"
echo "  2) bspwm          - bspwm config files"
echo "  3) hypr           - hypr config files"
echo "  4) nvim           - nvim config files"
echo "  5) all"
echo "  0) quit"
read -rp "Select [0-5]: " choice

case "${choice:-5}" in
    1) install_sublime ;;
    2) install_bspwm ;;
    3) install_hypr ;;
    4) install_nvim ;;
    5)
        install_sublime
        install_bspwm
        install_hypr
        install_nvim
        ;;
    0) exit 0 ;;
    *) echo "invalid choice" >&2; exit 1 ;;
esac
