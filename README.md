# DedSec-inspired Kali rice

A reversible DedSec-inspired XFCE interface for Kali Linux. It supports a live MP4 desktop wallpaper, a static wallpaper fallback, and a custom XFCE Terminal background. The `with-wallpaper-assets` branch bundles the provided wallpaper media; see [assets/README.md](assets/README.md).

## Target

- Kali Linux using XFCE
- `xfconf-query` available (provided by XFCE)
- zsh for the optional prompt styling

The installer changes only the current account's XFCE GTK/window-manager theme, GTK widget/panel styling, desktop wallpaper settings, XFCE Terminal configuration, autostart entry, and managed block in `~/.zshrc`. It does not change Kali security settings.

## Install

From a terminal in the target account's XFCE session:

```bash
./setup.sh
```

`setup.sh` installs the required Kali packages without interactive package-configuration dialogs, builds and installs `xwinwrap` if needed, then applies the interface. It uses `sudo` only for system package/build installation when run as a regular user. For root, start a root XFCE session and run the script directly, without `sudo`. The setup also requires the wallpaper files described in [assets/README.md](assets/README.md).

Run it once in each account's own XFCE session if you want both the regular account and root customized. Settings, installed wallpaper copies, startup entries, and restore state remain separate for each account. The script checks for a previous install, backs up its restore state, and tries to uninstall it before reinstalling; if it cannot safely proceed, it stops and keeps the backup.

The setup installs zsh and zsh-syntax-highlighting. Open a new zsh terminal to see the neon prompt and command colors. A soft terminal bell is emitted as you type; its loudness depends on your desktop's configured bell volume.

The setup installs the xwinwrap build dependencies, builds xwinwrap, and installs mpv for the animated wallpaper. It starts immediately and automatically on future X11 XFCE sign-ins. Log out and back in to apply panel and window styling.

The installer saves prior XFCE values and terminal/GTK configuration under `~/.local/state/dedsec-kali-rice`. Setup backs up that restore state before reinstalling and stops if another existing file cannot safely be replaced.

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
