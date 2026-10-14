#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/rice.sh"

if [[ "$(uname -s)" != Linux ]] || [[ ! -r /etc/os-release ]]; then
    printf 'This setup script is for Kali Linux with XFCE.\n' >&2
    exit 1
fi
source /etc/os-release
if [[ "${ID:-}" != kali ]]; then
    printf 'Detected %s, not Kali Linux. No changes were made.\n' "${PRETTY_NAME:-an unsupported Linux distribution}" >&2
    exit 1
fi
if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
    printf 'HOME must point to the current account home directory.\n' >&2
    exit 1
fi
if [[ -n "${SUDO_USER:-}" ]]; then
    printf 'Start setup directly in the XFCE session of the account to configure; do not run it with sudo.\n' >&2
    exit 1
fi
if [[ "$(stat -c '%u' -- "$HOME")" != "$(id -u)" ]]; then
    printf 'The current account does not own HOME (%s); refusing to modify another account.\n' "$HOME" >&2
    exit 1
fi

for required_file in \
    "$SCRIPT_DIR/install.sh" \
    "$SCRIPT_DIR/uninstall.sh" \
    "$SCRIPT_DIR/assets/desktop-background.png" \
    "$SCRIPT_DIR/assets/terminal-background.png" \
    "$SCRIPT_DIR/assets/dedsec-live-wallpaper.mp4" \
    "$SCRIPT_DIR/assets/gtk.css"; do
    if [[ ! -r "$required_file" ]]; then
        printf 'Required project file is missing: %s\n' "$required_file" >&2
        printf 'Use the with-wallpaper-assets branch, then retry. No system changes were made.\n' >&2
        exit 1
    fi
done

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    printf 'Start this script from the target account’s XFCE graphical session.\n' >&2
    printf 'This configures only %s and cannot safely configure another account’s desktop session.\n' "$(id -un)" >&2
    exit 1
fi

if (( EUID != 0 )) && ! command -v sudo >/dev/null 2>&1; then
    printf 'Installing system dependencies needs root privileges. Run this as root in its XFCE session, or install sudo first.\n' >&2
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
    printf 'apt-get is required to install Kali dependencies.\n' >&2
    exit 1
fi
if ! command -v xfconf-query >/dev/null 2>&1; then
    printf 'xfconf-query is missing. This setup expects an existing Kali XFCE desktop.\n' >&2
    exit 1
fi

run_as_root() {
    if (( EUID == 0 )); then
        "$@"
    else
        sudo "$@"
    fi
}

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dedsec-kali-rice"
if [[ -e "$STATE_DIR" ]]; then
    backup_dir="$HOME/dedsec-kali-backup-$(date +%Y%m%d-%H%M%S)"
    if [[ -e "$backup_dir" ]]; then
        printf 'Refusing to overwrite existing backup: %s\n' "$backup_dir" >&2
        exit 1
    fi
    mkdir -m 700 -- "$backup_dir"
    cp -a -- "$STATE_DIR" "$backup_dir/state"
    printf 'Saved a copy of the previous restore state to %s/state\n' "$backup_dir"
    "$SCRIPT_DIR/uninstall.sh"
    if [[ -e "$STATE_DIR" ]]; then
        printf 'The previous installation could not be fully uninstalled. Its restore state and backup were kept; setup stopped.\n' >&2
        exit 1
    fi
fi

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
managed_paths=(
    "$DATA_HOME/backgrounds/dedsec-desktop.png"
    "$DATA_HOME/backgrounds/dedsec-terminal.png"
    "$DATA_HOME/backgrounds/dedsec-live-wallpaper.mp4"
    "$HOME/.local/lib/dedsec-kali-rice"
    "$HOME/.config/autostart/dedsec-live-wallpaper.desktop"
)
for path in "${managed_paths[@]}"; do
    if [[ -e "$path" ]]; then
        printf 'Setup will not overwrite an existing path: %s\n' "$path" >&2
        printf 'Move it aside yourself if it is an old DedSec install, then rerun setup.sh.\n' >&2
        exit 1
    fi
done

printf 'Installing Kali XFCE theme dependencies for %s...\n' "$(id -un)"
run_as_root apt-get update
run_as_root apt-get install -y \
    build-essential \
    git \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    mpv \
    x11proto-xext-dev \
    xorg-dev \
    xfce4-terminal \
    xfconf \
    zsh \
    zsh-syntax-highlighting

if ! command -v xwinwrap >/dev/null 2>&1; then
    if ! command -v make >/dev/null 2>&1; then
        printf 'make is missing after installing build-essential; cannot build xwinwrap.\n' >&2
        exit 1
    fi
    build_dir="$(mktemp -d "${TMPDIR:-/tmp}/dedsec-xwinwrap.XXXXXX")"
    trap 'rm -rf -- "$build_dir"' EXIT
    printf 'Building xwinwrap from its upstream source...\n'
    git clone --depth 1 https://github.com/r00tdaemon/xwinwrap.git "$build_dir/xwinwrap"
    make -C "$build_dir/xwinwrap" -j"$(nproc)"
    run_as_root make -C "$build_dir/xwinwrap" install
    if ! command -v xwinwrap >/dev/null 2>&1; then
        printf 'xwinwrap installation did not produce an executable on PATH.\n' >&2
        exit 1
    fi
fi

printf 'Applying the DedSec XFCE interface to %s...\n' "$(id -un)"
"$SCRIPT_DIR/install.sh"
printf 'Setup complete for %s. Log out and back in to refresh the full desktop theme.\n' "$(id -un)"
