#!/usr/bin/env bash
# uninstall.sh — remove dotfiles install artifacts (keeps ~/dotfiles checkout)
set -euo pipefail

[[ -n "${DOTFILES_ROOT+set}" ]] && _DOTFILES_ROOT_FROM_ENV=1
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
init_dotfiles_root_from_script

# Remove dest only when it is a symlink pointing at expected_src.
remove_dotfile_symlink() {
    local dest="$1" expected_src="$2"

    if [[ ! -L "$dest" ]]; then
        if [[ -e "$dest" ]]; then
            info "Leaving $dest (not a symlink)."
        fi
        return 0
    fi

    if [[ "$(readlink -f "$dest")" == "$(readlink -f "$expected_src")" ]]; then
        rm -f "$dest"
        info "Removed $dest"
    else
        info "Leaving $dest (symlink points elsewhere)."
    fi
}

# Drop lines from ~/.bashrc that this dotfiles install may have added.
clean_bashrc() {
    local bashrc="$HOME/.bashrc"
    [[ -f "$bashrc" ]] || return 0

    local tmp
    tmp=$(mktemp)
    cp "$bashrc" "$tmp"
    grep -Ev '^[[:space:]]*source[[:space:]]+"[^"]*/dotfiles/\.bashrc"[[:space:]]*$' "$tmp" > "${tmp}.new" || true
    mv "${tmp}.new" "$tmp"

    if ! cmp -s "$bashrc" "$tmp"; then
        mv "$tmp" "$bashrc"
        info "Cleaned dotfiles-related lines from ~/.bashrc"
    else
        rm -f "$tmp"
        info "~/.bashrc: no dotfiles lines to remove"
    fi
}

remove_user_local_binary() {
    local name="$1"
    local path="$HOME/.local/bin/$name"
    [[ -e "$path" ]] || return 0
    rm -f "$path"
    info "Removed $path"
}

main() {
    echo
    echo "════════════════════════════════════"
    echo "  Dotfiles Uninstaller"
    echo "════════════════════════════════════"
    info "Checkout: $DOTFILES_ROOT (kept)"

    ask "Remove dotfiles symlinks, ~/.bashrc hooks, and user-local installs?" \
        || die "Aborted."

    header "Config symlinks"
    remove_dotfile_symlink "$HOME/.vimrc" "$DOTFILES_ROOT/.vimrc"
    remove_dotfile_symlink "$HOME/.local/bin/vifm-preview" "$DOTFILES_ROOT/vifm/vifm-preview"
    remove_dotfile_symlink "$HOME/.config/vifm/vifmimgrc" "$DOTFILES_ROOT/vifm/vifmimgrc"
    remove_dotfile_symlink "$HOME/.config/vifm/vifmrc" "$DOTFILES_ROOT/vifm/vifmrc"
    remove_dotfile_symlink "$HOME/.config/vifm/colors/palenight.vifm" "$DOTFILES_ROOT/vifm/colors/palenight.vifm"

    header "~/.bashrc"
    clean_bashrc

    header "User-local tools"
    remove_user_local_binary fd
    remove_user_local_binary fdfind
    remove_user_local_binary bat
    remove_user_local_binary batcat
    remove_user_local_binary chafa
    remove_user_local_binary vifm
    rm -f "$HOME/.local/bin/vifmimg" "$HOME/.local/bin/vifmimg.upstream" "$HOME/.local/bin/vifmrun" 2>/dev/null || true

    if [[ -d "$HOME/.local/opt/fd" ]]; then
        rm -rf "$HOME/.local/opt/fd"
        info "Removed ~/.local/opt/fd"
    fi
    if [[ -d "$HOME/.local/opt/vifm-deps" ]]; then
        rm -rf "$HOME/.local/opt/vifm-deps"
        info "Removed ~/.local/opt/vifm-deps"
    fi
    if [[ -d "$HOME/.local/opt/vifm" ]]; then
        rm -rf "$HOME/.local/opt/vifm"
        info "Removed ~/.local/opt/vifm"
    fi
    if [[ -f "$HOME/.local/share/dotfiles/env.sh" ]]; then
        rm -f "$HOME/.local/share/dotfiles/env.sh"
        info "Removed ~/.local/share/dotfiles/env.sh"
    fi

    if [[ -f "$HOME/.local/bin/bashmarks.sh" ]]; then
        ask "Remove bashmarks (~/.local/bin/bashmarks.sh)?" \
            && { rm -f "$HOME/.local/bin/bashmarks.sh"; info "Removed bashmarks"; } \
            || info "Keeping bashmarks"
    fi

    if [[ -d "$HOME/.fzf" ]]; then
        ask "Remove fzf (~/.fzf)?" \
            && { rm -rf "$HOME/.fzf"; info "Removed ~/.fzf"; } \
            || info "Keeping ~/.fzf"
    fi

    if [[ -f "$HOME/.vim/autoload/plug.vim" ]]; then
        ask "Remove vim-plug and ~/.vim/plugged plugins?" \
            && { rm -f "$HOME/.vim/autoload/plug.vim"; rm -rf "$HOME/.vim/plugged"; info "Removed vim-plug"; } \
            || info "Keeping vim-plug"
    fi

    echo
    echo "════════════════════════════════════"
    echo "  Done.  Reinstall: $DOTFILES_ROOT/install.sh"
    echo "════════════════════════════════════"
    echo
}

main
