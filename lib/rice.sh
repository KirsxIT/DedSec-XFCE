STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dedsec-kali-rice"

require_xfce() {
    if [[ "$(uname -s)" != Linux ]]; then
        printf 'This rice targets Kali Linux; no system changes were made.\n' >&2
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
