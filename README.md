# DedSec-inspired Kali rice

A reversible DedSec-inspired XFCE interface for Kali Linux. It supports a live MP4 desktop wallpaper, a static wallpaper fallback, and a custom XFCE Terminal background. The `with-wallpaper-assets` branch bundles the provided wallpaper media; see [assets/README.md](assets/README.md).

## Target

- Kali Linux using XFCE
- `xfconf-query` available (provided by XFCE)
- zsh for the optional prompt styling

The installer changes only the current account's XFCE GTK/window-manager theme, GTK widget/panel styling, desktop wallpaper settings, XFCE Terminal configuration, autostart entry, and managed block in `~/.zshrc`. It does not change Kali security settings.

## Install

From a terminal in this project directory:

```bash
# Add your permitted wallpaper files to assets/ first; see assets/README.md.
./install.sh
```

Install for each account separately, from that account's own graphical XFCE session:

1. Log into your regular Kali user in XFCE and run `./install.sh` for that user.
2. If root has its own XFCE desktop session, log into that session and run `./install.sh` there to theme root too.

The script detects whether the current account is `root` or a regular user, checks that it owns `HOME`, and scopes settings, media, startup entries, and saved restore state to that account. **Do not run it with `sudo`** from another account's desktop: XFCE settings belong to the active session and running via `sudo` can target the wrong home or session. Root styling requires an actual root XFCE session; installing for the regular account does not require root.

Open a new zsh terminal to see the neon prompt. A soft terminal bell is emitted as you type; its loudness depends on your desktop's configured bell volume. The installer enables XFCE Terminal's audible bell.

Live syntax highlighting colors commands, builtins, functions, aliases, quoted arguments, redirections, and unknown commands. On Kali, install the optional highlighter if needed:

```bash
sudo apt install zsh-syntax-highlighting
```

For the animated MP4 wallpaper, install `mpv` and `xwinwrap`. On Kali, install the build dependencies and build xwinwrap from its upstream source:

```bash
sudo apt install mpv git build-essential xorg-dev libx11-dev x11proto-xext-dev libxrender-dev libxext-dev
git clone https://github.com/r00tdaemon/xwinwrap.git
cd xwinwrap
make
sudo make install
```

When `mpv` and `xwinwrap` are available, the wallpaper starts immediately and automatically on future X11 XFCE sign-ins. If either player is missing, the static desktop image remains visible. Start a new terminal after installing syntax highlighting. Log out and back in to apply panel and window styling.

The installer saves prior XFCE values and terminal/GTK configuration under `~/.local/state/dedsec-kali-rice`. It refuses to overwrite an existing saved installation or managed wallpaper, player directory, or autostart entry.

## Uninstall

```bash
./uninstall.sh
```

This stops the live wallpaper, restores saved XFCE/window-manager and terminal/GTK configuration, removes its autostart entry and the managed prompt block, deletes the installed wallpapers, and removes saved state.

Run the uninstaller separately in each account's XFCE session that you themed. Each account has its own backup and restore state.

## Notes

- The theme uses Kali's `Kali-Dark` GTK and icon themes.
- Neon green GTK/panel accents, dark menus, and matching Kali-Dark window decorations provide a consistent desktop treatment without rearranging the user's XFCE panels.
- The zsh prompt and per-keystroke terminal-bell widget are plugin-free and leave other `.zshrc` content untouched.
- Live command-line syntax colors use Kali's optional `zsh-syntax-highlighting` package; the installer does not install packages.
- XFCE Terminal uses the supplied skull-pattern background, scaled to the terminal window and darkened slightly for legibility.
- On `main`, wallpaper media is excluded from Git; on `with-wallpaper-assets`, the provided assets are included. The installer checks for all required assets before making system changes.
- Run the scripts directly in the XFCE session for the account being customized (regular user or root), never through `sudo`.
