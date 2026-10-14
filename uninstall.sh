#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/rice.sh"

remove_if_unchanged() {
    local file="$1" checksum_file="$2" expected actual
    [[ -e "$file" ]] || return 0
    if [[ ! -f "$checksum_file" ]]; then
        printf 'Keeping file without a saved checksum: %s\n' "$file" >&2
        return 0
    fi
    expected="$(< "$checksum_file")"
    actual="$(sha256sum -- "$file")"
    actual="${actual%% *}"
    if [[ "$actual" == "$expected" ]]; then
        rm -f -- "$file"
    else
        printf 'Keeping file changed since installation: %s\n' "$file" >&2
    fi
}

if [[ ! -d "$STATE_DIR" ]]; then
    printf 'No saved installation found at %s.\n' "$STATE_DIR" >&2
    exit 1
fi

PLAYER_SCRIPT="$HOME/.local/lib/dedsec-kali-rice/wallpaper.sh"
if [[ -f "$STATE_DIR/format-version" && -f "$PLAYER_SCRIPT" && -f "$STATE_DIR/files/wallpaper-player.sha256" ]]; then
    expected_player_hash="$(< "$STATE_DIR/files/wallpaper-player.sha256")"
    actual_player_hash="$(sha256sum -- "$PLAYER_SCRIPT")"
    actual_player_hash="${actual_player_hash%% *}"
    if [[ "$actual_player_hash" == "$expected_player_hash" ]]; then
        /bin/bash "$PLAYER_SCRIPT" stop
    else
        printf 'Skipping modified wallpaper player script: %s\n' "$PLAYER_SCRIPT" >&2
    fi
fi

while IFS=$'\t' read -r channel property existed type value; do
    [[ -n "${channel:-}" ]] || continue
    if [[ "$existed" == 1 ]]; then
        xfconf-query -c "$channel" -p "$property" --create -t "$type" -s "$value"
    elif xfconf-query -c "$channel" -p "$property" >/dev/null 2>&1; then
        xfconf-query -c "$channel" -p "$property" --reset
    fi
done < "$STATE_DIR/xfconf.tsv"

TERMINAL_RC="$HOME/.config/xfce4/terminal/terminalrc"
if [[ -e "$STATE_DIR/files/terminalrc-present" ]]; then
    cp -p -- "$STATE_DIR/files/terminalrc" "$TERMINAL_RC"
else
    rm -f -- "$TERMINAL_RC"
fi

GTK_CSS="$HOME/.config/gtk-3.0/gtk.css"
if [[ -f "$STATE_DIR/format-version" ]]; then
    if [[ -e "$STATE_DIR/files/gtk-css-present" ]]; then
        cp -p -- "$STATE_DIR/files/gtk.css" "$GTK_CSS"
    else
        rm -f -- "$GTK_CSS"
    fi
fi

if [[ -f "$HOME/.zshrc" && ( -e "$STATE_DIR/zshrc-managed" || ! -f "$STATE_DIR/format-version" ) ]]; then
    temp_zshrc="$(mktemp)"
    awk '
        $0 == "# >>> dedsec-kali-rice >>>" { skip = 1; next }
        $0 == "# <<< dedsec-kali-rice <<<" { skip = 0; next }
        !skip { print }
    ' "$HOME/.zshrc" > "$temp_zshrc"
    cat "$temp_zshrc" > "$HOME/.zshrc"
    rm -f -- "$temp_zshrc"
fi

if [[ -f "$STATE_DIR/format-version" ]]; then
    remove_if_unchanged "$HOME/.config/autostart/dedsec-live-wallpaper.desktop" "$STATE_DIR/files/autostart.sha256"
    remove_if_unchanged "$HOME/.local/lib/dedsec-kali-rice/wallpaper.sh" "$STATE_DIR/files/wallpaper-player.sha256"
    if [[ -d "$HOME/.local/lib/dedsec-kali-rice" ]] && ! rmdir "$HOME/.local/lib/dedsec-kali-rice"; then
        printf 'Leaving non-empty player directory in place: %s\n' "$HOME/.local/lib/dedsec-kali-rice" >&2
    fi
fi

if [[ -f "$STATE_DIR/wallpaper-path" ]]; then
    wallpaper="$(< "$STATE_DIR/wallpaper-path")"
    if [[ -f "$STATE_DIR/format-version" ]]; then
        remove_if_unchanged "$wallpaper" "$STATE_DIR/files/desktop-background.sha256"
    else
        rm -f -- "$wallpaper"
    fi
fi

if [[ -f "$STATE_DIR/terminal-image-path" ]]; then
    terminal_image="$(< "$STATE_DIR/terminal-image-path")"
    if [[ -f "$STATE_DIR/format-version" ]]; then
        remove_if_unchanged "$terminal_image" "$STATE_DIR/files/terminal-background.sha256"
    else
        rm -f -- "$terminal_image"
    fi
fi

if [[ -f "$STATE_DIR/live-wallpaper-path" ]]; then
    live_wallpaper="$(< "$STATE_DIR/live-wallpaper-path")"
    remove_if_unchanged "$live_wallpaper" "$STATE_DIR/files/live-wallpaper.sha256"
fi

rm -rf -- "$STATE_DIR"
printf 'Saved XFCE, window, and terminal settings restored; the managed prompt and wallpaper files were removed.\n'
printf 'Log out and back in if the desktop has not refreshed its appearance.\n'
