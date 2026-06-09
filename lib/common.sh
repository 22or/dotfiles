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
