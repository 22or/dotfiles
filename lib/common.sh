# lib/common.sh — shared helpers for install.sh and uninstall.sh
# shellcheck shell=bash

# Set by parent before sourcing when DOTFILES_ROOT was exported by the user.
: "${_DOTFILES_ROOT_FROM_ENV:=0}"

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"

init_dotfiles_root_from_script() {
    local src="${BASH_SOURCE[1]:-${BASH_SOURCE[0]:-}}"
    if (( _DOTFILES_ROOT_FROM_ENV )); then
        export DOTFILES_ROOT
        return 0
    fi
    if [[ -n "$src" && -f "$src" ]]; then
        local dir
        dir=$(cd "$(dirname "$src")" && pwd)
        if [[ -f "$dir/.bashrc" && -f "$dir/install.sh" ]]; then
            DOTFILES_ROOT="$dir"
            export DOTFILES_ROOT
        fi
    fi
}

die()  { echo "  ERROR: $*" >&2; exit 1; }
info() { echo "  $*"; }
header() { echo; echo "── $* ──"; }

ask() {
    local answer
    while true; do
        read -r -p "  $* [Y/n]: " answer
        answer="${answer:-y}"
        case "$answer" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
        esac
    done
}

have() { command -v "$1" &>/dev/null; }

# arch_triple <flavor>  — musl (sharkdp tarballs), gnu (glibc lib dirs), chafa (static tarball)
arch_triple() {
    local flavor="${1:?}"
    case "$(uname -m)" in
        x86_64)
            case "$flavor" in
                musl)        echo x86_64-unknown-linux-musl ;;
                gnu|chafa)   echo x86_64-linux-gnu ;;
            esac
            ;;
        aarch64|arm64)
            case "$flavor" in
                musl) echo aarch64-unknown-linux-musl ;;
                gnu)  echo aarch64-linux-gnu ;;
                chafa) return 1 ;;
            esac
            ;;
        armv7l|armv6*|armv7*)
            case "$flavor" in
                musl)  echo arm-unknown-linux-musleabihf ;;
                gnu)   echo arm-linux-gnueabihf ;;
                chafa) echo armv7l-linux-gnu ;;
            esac
            ;;
        *)
            case "$flavor" in
                musl)        echo x86_64-unknown-linux-musl ;;
                gnu|chafa)   echo x86_64-linux-gnu ;;
            esac
            ;;
    esac
}

# Append a literal line to a file only if it is not already present.
append_once() {
    local line="$1" file="$2"
    grep -qxF "$line" "$file" 2>/dev/null || printf '\n%s\n' "$line" >> "$file"
}

# Portable download: prefers curl, falls back to wget.
fetch() {
    local url="$1" dest="$2"
    if have curl; then
        curl -fsSL "$url" -o "$dest"
    elif have wget; then
        wget -q "$url" -O "$dest"
    else
        die "Neither curl nor wget found. Install one and retry."
    fi
}

# Same as fetch but returns 1 on failure (no die).
fetch_soft() {
    local url="$1" dest="$2"
    if have curl; then
        curl -fsSL "$url" -o "$dest" && return 0
    elif have wget; then
        wget -q "$url" -O "$dest" && return 0
    fi
    return 1
}

# True when dest is a hard link to src (same device + inode), not merely equal content.
same_inode() {
    local a="$1" b="$2"
    [[ -e "$a" && -e "$b" ]] || return 1
    [[ "$(stat -c '%d:%i' "$a" 2>/dev/null)" == "$(stat -c '%d:%i' "$b" 2>/dev/null)" ]]
}

# Symlink dest → src. Skips existing regular files and foreign symlinks.
link_dotfile() {
    local src="$1" dest="$2"

    if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest" 2>/dev/null)" == "$(readlink -f "$src" 2>/dev/null)" ]]; then
        info "$dest → $src already configured."
        return 0
    elif [[ -L "$dest" ]]; then
        info "$dest is a symlink (not pointing at $src). Leaving unchanged."
        return 1
    elif same_inode "$dest" "$src"; then
        # Hard link to src: same file already, so replacing it with a symlink loses nothing.
        rm -f "$dest"
        ln -s "$src" "$dest"
        info "Replaced hard link $dest with symlink → $src"
        return 0
    elif [[ -e "$dest" ]]; then
        info "WARNING: $dest exists and is not a symlink. Skipping to avoid data loss."
        info "         Run uninstall.sh then install.sh for a clean reinstall."
        return 1
    fi

    ln -s "$src" "$dest"
    info "Linked $dest → $src"
}
