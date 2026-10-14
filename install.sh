#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/rice.sh"

require_xfce

for required_file in \
    "$SCRIPT_DIR/assets/desktop-background.png" \
    "$SCRIPT_DIR/assets/terminal-background.png" \
    "$SCRIPT_DIR/assets/dedsec-live-wallpaper.mp4" \
    "$SCRIPT_DIR/assets/gtk.css" \
    "$SCRIPT_DIR/wallpaper.sh"; do
    if [[ ! -r "$required_file" ]]; then
        printf 'Required project file is missing: %s\n' "$required_file" >&2
        printf 'See assets/README.md for wallpaper setup. No system changes were made.\n' >&2
        exit 1
    fi
done

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
WALLPAPER="$DATA_HOME/backgrounds/dedsec-desktop.png"
TERMINAL_IMAGE="$DATA_HOME/backgrounds/dedsec-terminal.png"
LIVE_WALLPAPER="$DATA_HOME/backgrounds/dedsec-live-wallpaper.mp4"
PLAYER_DIR="$HOME/.local/lib/dedsec-kali-rice"
AUTOSTART_ENTRY="$HOME/.config/autostart/dedsec-live-wallpaper.desktop"
for managed_file in "$WALLPAPER" "$TERMINAL_IMAGE" "$LIVE_WALLPAPER" "$PLAYER_DIR" "$AUTOSTART_ENTRY"; do
    if [[ -e "$managed_file" ]]; then
        printf 'Refusing to overwrite existing file: %s\n' "$managed_file" >&2
        exit 1
    fi
done

if [[ -e "$STATE_DIR" ]]; then
    printf 'A saved installation already exists at %s. Run uninstall.sh before reinstalling.\n' "$STATE_DIR" >&2
    exit 1
fi

mkdir -p "$STATE_DIR" "$STATE_DIR/files" "$HOME/.config/xfce4/terminal" "$HOME/.config/gtk-3.0" "$HOME/.config/autostart" "$DATA_HOME/backgrounds" "$HOME/.local/lib" "$PLAYER_DIR"
touch "$STATE_DIR/xfconf.tsv"
printf '2\n' > "$STATE_DIR/format-version"

TERMINAL_RC="$HOME/.config/xfce4/terminal/terminalrc"
if [[ -e "$TERMINAL_RC" ]]; then
    cp -p -- "$TERMINAL_RC" "$STATE_DIR/files/terminalrc"
    : > "$STATE_DIR/files/terminalrc-present"
fi

GTK_CSS="$HOME/.config/gtk-3.0/gtk.css"
if [[ -e "$GTK_CSS" ]]; then
    cp -p -- "$GTK_CSS" "$STATE_DIR/files/gtk.css"
    : > "$STATE_DIR/files/gtk-css-present"
fi

remember_xfconf xsettings /Net/ThemeName
remember_xfconf xsettings /Net/IconThemeName
remember_xfconf xfwm4 /general/theme

xfconf-query -c xsettings -p /Net/ThemeName --create -t string -s Kali-Dark
xfconf-query -c xsettings -p /Net/IconThemeName --create -t string -s Kali-Dark
xfconf-query -c xfwm4 -p /general/theme --create -t string -s Kali-Dark

cp -- "$SCRIPT_DIR/assets/desktop-background.png" "$WALLPAPER"
printf '%s\n' "$WALLPAPER" > "$STATE_DIR/wallpaper-path"
sha256sum -- "$WALLPAPER" | cut -d ' ' -f 1 > "$STATE_DIR/files/desktop-background.sha256"
cp -- "$SCRIPT_DIR/assets/terminal-background.png" "$TERMINAL_IMAGE"
printf '%s\n' "$TERMINAL_IMAGE" > "$STATE_DIR/terminal-image-path"
sha256sum -- "$TERMINAL_IMAGE" | cut -d ' ' -f 1 > "$STATE_DIR/files/terminal-background.sha256"
cp -- "$SCRIPT_DIR/assets/dedsec-live-wallpaper.mp4" "$LIVE_WALLPAPER"
printf '%s\n' "$LIVE_WALLPAPER" > "$STATE_DIR/live-wallpaper-path"
sha256sum -- "$LIVE_WALLPAPER" | cut -d ' ' -f 1 > "$STATE_DIR/files/live-wallpaper.sha256"
cp -- "$SCRIPT_DIR/wallpaper.sh" "$PLAYER_DIR/wallpaper.sh"
chmod 700 "$PLAYER_DIR/wallpaper.sh"
sha256sum -- "$PLAYER_DIR/wallpaper.sh" | cut -d ' ' -f 1 > "$STATE_DIR/files/wallpaper-player.sha256"
printf '%s\n' "$PLAYER_DIR" > "$STATE_DIR/player-dir"

cp -- "$SCRIPT_DIR/assets/gtk.css" "$GTK_CSS"

desktop_properties="$(xfconf-query -c xfce4-desktop -l)"
found_wallpaper_property=0
while IFS= read -r property; do
    case "$property" in
        */last-image)
            found_wallpaper_property=1
            remember_xfconf xfce4-desktop "$property"
            xfconf-query -c xfce4-desktop -p "$property" --create -t string -s "$WALLPAPER"
            style_property="${property%last-image}image-style"
            remember_xfconf xfce4-desktop "$style_property"
            xfconf-query -c xfce4-desktop -p "$style_property" --create -t int -s 5
            ;;
    esac
done <<< "$desktop_properties"

if [[ "$found_wallpaper_property" == 0 ]]; then
    property=/backdrop/screen0/monitor0/workspace0/last-image
    remember_xfconf xfce4-desktop "$property"
    xfconf-query -c xfce4-desktop -p "$property" --create -t string -s "$WALLPAPER"
    style_property=/backdrop/screen0/monitor0/workspace0/image-style
    remember_xfconf xfce4-desktop "$style_property"
    xfconf-query -c xfce4-desktop -p "$style_property" --create -t int -s 5
fi

if ! grep -Fq '# >>> dedsec-kali-rice >>>' "$HOME/.zshrc" 2>/dev/null; then
    : > "$STATE_DIR/zshrc-managed"
    cat >> "$HOME/.zshrc" <<'ZSH'

# >>> dedsec-kali-rice >>>
autoload -Uz colors && colors
setopt prompt_subst
PROMPT='%F{green}DEDSEC%f %F{magenta}//%f %F{red}HACKING%f %F{magenta}::%f %F{cyan}CTOS%f
%F{cyan}╭─[%F{magenta}%n%F{white}@%F{green}%m%F{cyan}]─[%F{yellow}%~%F{cyan}]%f
%F{cyan}╰─%F{red}❯%f '

dedsec_self_insert_with_bell() {
  print -n '\a'
  zle .self-insert
}
zle -N self-insert dedsec_self_insert_with_bell

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=white'
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[comment]='fg=black,bold'

for dedsec_highlighting in \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -r "$dedsec_highlighting" ]]; then
    source "$dedsec_highlighting"
    break
  fi
done
# <<< dedsec-kali-rice <<<
ZSH
fi

cat > "$TERMINAL_RC" <<TERMINAL
[Configuration]
ColorBackground=#0b0d10
ColorForeground=#e6e9ed
ColorCursor=#ff3040
ColorPalette=#11151a;#ff3040;#36d17c;#e4d26a;#54a9ff;#be78ff;#45d6d0;#c4c9d0;#4c5661;#ff5260;#59e394;#f3df79;#76baff;#d19aff;#6be5de;#f3f5f7
ColorUseTheme=FALSE
BackgroundMode=TERMINAL_BACKGROUND_IMAGE
BackgroundImageFile=$TERMINAL_IMAGE
BackgroundImageStyle=TERMINAL_BACKGROUND_STYLE_SCALED
BackgroundDarkness=0.400000
TitleInitial=DEDSEC // CTOS
FontName=Monospace 10
MiscBell=TRUE
ScrollingOnOutput=FALSE
TERMINAL

desktop_escape_path="${PLAYER_DIR//\\/\\\\}"
desktop_escape_path="${desktop_escape_path//\"/\\\"}"
cat > "$AUTOSTART_ENTRY" <<AUTOSTART
[Desktop Entry]
Type=Application
Name=DedSec Live Wallpaper
Comment=Loop the DedSec Watch Dogs wallpaper behind the desktop
Exec=/bin/bash "$desktop_escape_path/wallpaper.sh" start
OnlyShowIn=XFCE;
Terminal=false
X-GNOME-Autostart-enabled=true
AUTOSTART
sha256sum -- "$AUTOSTART_ENTRY" | cut -d ' ' -f 1 > "$STATE_DIR/files/autostart.sha256"

if command -v mpv >/dev/null 2>&1 && command -v xwinwrap >/dev/null 2>&1; then
    "$PLAYER_DIR/wallpaper.sh" start
fi

printf 'DedSec XFCE interface installed for account %s (HOME=%s).\n' "$(id -un)" "$HOME"
printf 'Neon panel styling, Kali-Dark window theme, supplied live wallpaper, terminal skin, and zsh prompt are configured for this account only.\n'
if ! command -v mpv >/dev/null 2>&1 || ! command -v xwinwrap >/dev/null 2>&1; then
    printf 'Live wallpaper needs mpv and xwinwrap. Until installed, XFCE shows the supplied static fallback wallpaper.\n'
    printf 'See README.md for the X11 live-wallpaper dependencies and setup.\n'
fi
if ! [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh || -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    printf 'For live command-line syntax colors, install zsh-syntax-highlighting: sudo apt install zsh-syntax-highlighting\n'
fi
printf 'To restore saved settings, run: %s/uninstall.sh\n' "$SCRIPT_DIR"
