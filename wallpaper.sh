#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dedsec-kali-rice"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
WALLPAPER="$DATA_HOME/backgrounds/dedsec-live-wallpaper.mp4"
PID_FILE="$STATE_DIR/wallpaper.pid"
LOG_FILE="$STATE_DIR/wallpaper.log"

start_wallpaper() {
    if [[ "${XDG_SESSION_TYPE:-x11}" != x11 ]]; then
        printf 'DedSec live wallpaper requires an X11 session; XFCE will keep its static fallback.\n' >&2
        return 0
    fi
    if ! command -v mpv >/dev/null 2>&1 || ! command -v xwinwrap >/dev/null 2>&1; then
        printf 'DedSec live wallpaper needs both mpv and xwinwrap; XFCE will keep its static fallback.\n' >&2
        return 0
    fi
    if [[ ! -r "$WALLPAPER" ]]; then
        printf 'DedSec live wallpaper file is missing: %s\n' "$WALLPAPER" >&2
        return 1
    fi

    if [[ -f "$PID_FILE" ]]; then
        local existing_pid existing_command
        existing_pid="$(< "$PID_FILE")"
        if [[ "$existing_pid" =~ ^[0-9]+$ ]] && (( existing_pid > 1 )); then
            existing_command="$(ps -p "$existing_pid" -o args= 2>/dev/null || true)"
            if [[ -n "$existing_command" && "$existing_command" == *xwinwrap* && "$existing_command" == *"$WALLPAPER"* ]]; then
                return 0
            fi
        fi
        rm -f -- "$PID_FILE"
    fi

    mkdir -p -- "$STATE_DIR"
    xwinwrap -fdt -fs -ni -s -st -sp -b -nf -- \
        mpv --wid WID --loop-file=inf --no-audio --no-osc --no-osd-bar \
        --no-input-default-bindings --really-quiet -- "$WALLPAPER" \
        >> "$LOG_FILE" 2>&1 &
    local player_pid=$!
    printf '%s\n' "$player_pid" > "$PID_FILE"
    sleep 1
    local player_command
    player_command="$(ps -p "$player_pid" -o args= 2>/dev/null || true)"
    if [[ -z "$player_command" || "$player_command" != *xwinwrap* ]]; then
        rm -f -- "$PID_FILE"
        printf 'DedSec live wallpaper did not start; inspect %s\n' "$LOG_FILE" >&2
        return 1
    fi
}

stop_wallpaper() {
    [[ -f "$PID_FILE" ]] || return 0
    local player_pid player_command
    player_pid="$(< "$PID_FILE")"
    if [[ "$player_pid" =~ ^[0-9]+$ ]] && (( player_pid > 1 )); then
        player_command="$(ps -p "$player_pid" -o args= 2>/dev/null || true)"
        if [[ -n "$player_command" && "$player_command" == *xwinwrap* && "$player_command" == *"$WALLPAPER"* ]]; then
            kill "$player_pid"
        fi
    fi
    while read -r process_pid process_command; do
        if [[ "$process_pid" != "$$" && "$process_command" == *mpv* && "$process_command" == *"$WALLPAPER"* ]]; then
            kill "$process_pid"
        fi
    done < <(ps -eo pid=,args=)
    rm -f -- "$PID_FILE"
}

case "${1:-start}" in
    start) start_wallpaper ;;
    stop) stop_wallpaper ;;
    *)
        printf 'Usage: %s [start|stop]\n' "$0" >&2
        exit 2
        ;;
esac
