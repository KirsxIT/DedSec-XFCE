STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dedsec-kali-rice"

require_xfce() {
    if [[ "$(uname -s)" != Linux ]]; then
        printf 'This rice targets Kali Linux; no system changes were made.\n' >&2
        exit 1
    fi
    if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
        printf 'HOME must point to the current account home directory.\n' >&2
        exit 1
    fi
    if [[ -n "${SUDO_USER:-}" ]]; then
        printf 'Run this script directly inside the XFCE session of the account you want to customize; do not use sudo.\n' >&2
        printf 'For root styling, log into root XFCE and run it there. For user styling, log into that user XFCE and run it there.\n' >&2
        exit 1
    fi
    local account_uid home_uid
    account_uid="$(id -u)"
    home_uid="$(stat -c '%u' -- "$HOME")"
    if [[ "$home_uid" != "$account_uid" ]]; then
        printf 'The current account does not own HOME (%s); refusing to modify another account.\n' "$HOME" >&2
        exit 1
    fi
    if ! command -v xfconf-query >/dev/null 2>&1; then
        printf 'xfconf-query is required. This project targets Kali XFCE.\n' >&2
        exit 1
    fi
}

remember_xfconf() {
    local channel="$1" property="$2" value type
    if grep -Fq "$(printf '%s\t%s\t' "$channel" "$property")" "$STATE_DIR/xfconf.tsv"; then
        return
    fi
    if value="$(xfconf-query -c "$channel" -p "$property" -v 2>/dev/null)"; then
        type="$(xfconf-query -c "$channel" -p "$property" -T)"
        printf '%s\t%s\t1\t%s\t%s\n' "$channel" "$property" "$type" "$value" >> "$STATE_DIR/xfconf.tsv"
    else
        printf '%s\t%s\t0\t-\t-\n' "$channel" "$property" >> "$STATE_DIR/xfconf.tsv"
    fi
}
