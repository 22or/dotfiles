#!/usr/bin/env bash
# install.sh — dotfiles installer
# Tested on Debian/Ubuntu x86_64, aarch64, armv7.
set -euo pipefail


# ─── Helpers ──────────────────────────────────────────────────────────────────

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


# ─── Architecture detection ───────────────────────────────────────────────────

fd_target_triple() {
    case "$(uname -m)" in
        x86_64)        echo "x86_64-unknown-linux-musl" ;;
        aarch64|arm64) echo "aarch64-unknown-linux-musl" ;;
        armv7*)        echo "arm-unknown-linux-musleabihf" ;;
        *)             die "Unsupported architecture: $(uname -m). Install fd manually: https://github.com/sharkdp/fd/releases" ;;
    esac
}


# ─── Prerequisites ────────────────────────────────────────────────────────────

check_prerequisites() {
    header "Prerequisites"
    have git || die "git is required but not found. Install git and retry."
    info "git: ok"
}


# ─── Dotfiles ─────────────────────────────────────────────────────────────────

install_dotfiles() {
    header "Dotfiles"

    if [[ -d ~/dotfiles ]]; then
        info "~/dotfiles already exists — skipping clone."
    else
        git clone https://github.com/22or/dotfiles.git ~/dotfiles
        info "Cloned into ~/dotfiles."
    fi

    # .vimrc symlink
    if [[ -L ~/.vimrc ]]; then
        info "~/.vimrc symlink already in place."
    elif [[ -e ~/.vimrc ]]; then
        info "WARNING: ~/.vimrc exists and is not a symlink. Skipping to avoid data loss."
        info "         Back it up and rerun, or manually: ln -sf ~/dotfiles/.vimrc ~/.vimrc"
    else
        ln -s ~/dotfiles/.vimrc ~/.vimrc
        info "Linked ~/.vimrc → ~/dotfiles/.vimrc"
    fi

    # Source dotfiles/.bashrc from ~/.bashrc
    local source_line='source "$HOME/dotfiles/.bashrc"'
    if append_once "$source_line" ~/.bashrc; then
        :
    fi
    info "dotfiles/.bashrc sourced in ~/.bashrc"
}


# ─── vim-plug ─────────────────────────────────────────────────────────────────
# The vimrc uses vim-plug (call plug#begin / call plug#end).
# Without plug.vim, Vim will throw errors on every startup.

install_vim_plug() {
    header "vim-plug"

    local plug_path=~/.vim/autoload/plug.vim

    if [[ -f "$plug_path" ]]; then
        info "vim-plug already installed."
        return
    fi

    info "Installing vim-plug..."
    mkdir -p ~/.vim/autoload
    fetch \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
        "$plug_path"

    info "Running :PlugInstall (this may take a moment)..."
    # -E: skip .vimrc, pick it up via -u; -s: silent batch mode
    vim -es -u ~/.vimrc +PlugInstall +qall || true
    info "Plugins installed."
}


# ─── fzf ──────────────────────────────────────────────────────────────────────
# The vimrc binds <C-p> to :Files (fzf.vim).
# The bashrc sources fzf key-bindings and defines FZF_* env vars.
# The bashrc's key-bindings path (/usr/share/doc/fzf/examples/...) only exists
# for apt-installed fzf. A fallback for git-installed fzf is appended below.

install_fzf() {
    header "fzf"

    if have fzf; then
        info "fzf already installed: $(command -v fzf)"
        _ensure_fzf_keybindings
        return
    fi

    ask "fzf not found. Install from git?" || return 0

    if [[ -d ~/.fzf ]]; then
        info "~/.fzf already exists — running install script."
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    fi

    # --no-update-rc  : don't touch .bashrc/.zshrc (we manage that ourselves)
    # --key-bindings  : install Ctrl-T, Ctrl-R, Alt-C bindings
    # --completion    : install ** tab-completion
    ~/.fzf/install --no-update-rc --key-bindings --completion

    append_once 'export PATH="$HOME/.fzf/bin:$PATH"' ~/.bashrc

    _ensure_fzf_keybindings
    info "fzf installed into ~/.fzf"
}

# The dotfiles .bashrc sources the apt path for fzf key-bindings. If fzf was
# installed from git, that file doesn't exist and bindings are silently absent.
# Append a fallback that covers the git-installed location.
_ensure_fzf_keybindings() {
    local git_bindings='[[ -f ~/.fzf/shell/key-bindings.bash ]] && source ~/.fzf/shell/key-bindings.bash'
    append_once "$git_bindings" ~/.bashrc
    info "fzf key-bindings fallback ensured in ~/.bashrc"
}


# ─── fd ───────────────────────────────────────────────────────────────────────
# The vimrc FZF_DEFAULT_COMMAND and every bashrc FZF_* var call 'fdfind'.
# The fd releases ship a binary named 'fd', so we create a 'fdfind' symlink.

FD_VERSION="10.4.2"
VIFM_VERSION="0.14.3"

install_fd() {
    header "fd (fdfind)"

    if have fdfind; then
        info "fdfind already available: $(command -v fdfind)"
        return
    fi

    # If plain 'fd' exists (e.g. apt install fd-find on older Debian uses 'fd')
    # try to create a fdfind symlink in a writable location.
    if have fd; then
        info "'fd' found but 'fdfind' is not."
        local fd_bin
        fd_bin=$(command -v fd)
        if [[ -w /usr/local/bin ]]; then
            ln -sf "$fd_bin" /usr/local/bin/fdfind
            info "Created: /usr/local/bin/fdfind → $fd_bin"
        else
            info "Cannot write to /usr/local/bin. Trying ~/.local/bin..."
            mkdir -p ~/.local/bin
            ln -sf "$fd_bin" ~/.local/bin/fdfind
            append_once 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc
            info "Created: ~/.local/bin/fdfind → $fd_bin"
        fi
        return
    fi

    ask "fd not found. Download fd v${FD_VERSION}?" || return 0

    local triple archive url tmpdir
    triple=$(fd_target_triple)
    archive="fd-v${FD_VERSION}-${triple}.tar.gz"
    url="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/${archive}"
    tmpdir=$(mktemp -d)
    # Clean up the temp dir on exit, error, or interrupt.
    trap 'rm -rf "$tmpdir"' RETURN INT TERM

    info "Downloading ${archive}..."
    fetch "$url" "$tmpdir/$archive"

    mkdir -p ~/.fdfind
    tar -xzf "$tmpdir/$archive" -C ~/.fdfind --strip-components=1

    # The tarball contains 'fd'. Symlink 'fdfind' so dotfiles work unchanged.
    ln -sf ~/.fdfind/fd ~/.fdfind/fdfind

    append_once 'export PATH="$HOME/.fdfind:$PATH"' ~/.bashrc
    info "fd installed into ~/.fdfind"
    info "fdfind symlink created."

	trap - RETURN INT TERM
}


# ─── vifm ─────────────────────────────────────────────────────────────────────

install_vifm() {
    header "vifm"

    if have vifm; then
        info "vifm already installed: $(command -v vifm)"
        return
    fi

    ask "vifm not found. Install vifm v${VIFM_VERSION}?" || return 0

    local tmpdir
    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' RETURN INT TERM

    mkdir -p "$HOME/.local/bin"

    case "$(uname -m)" in
        x86_64)
            info "Downloading vifm ${VIFM_VERSION} AppImage..."
            local appimg="$tmpdir/vifm.AppImage"
            fetch \
                "https://github.com/vifm/vifm/releases/download/v${VIFM_VERSION}/vifm-v${VIFM_VERSION}-x86_64.AppImage" \
                "$appimg"
            chmod +x "$appimg"
            ( cd "$tmpdir" && ./vifm.AppImage --appimage-extract >/dev/null )
            cp "$tmpdir/squashfs-root/usr/bin/vifm" "$HOME/.local/bin/vifm"
            ;;
        *)
            info "Downloading vifm package via apt-get..."
            ( cd "$tmpdir" && apt-get download vifm ) || die "apt-get download failed. Install vifm manually."
            dpkg -x "$tmpdir"/vifm_*.deb "$tmpdir/pkg"
            cp "$tmpdir/pkg/usr/bin/vifm" "$HOME/.local/bin/vifm"
            ;;
    esac

    append_once 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc
    info "vifm installed into ~/.local/bin"

    trap - RETURN INT TERM
}


# ─── bat (optional) ───────────────────────────────────────────────────────────
# ff() in bashrc uses bat for syntax-highlighted previews when available.
# No install step — just inform the user.

check_bat() {
    header "bat (optional)"
    if have bat; then
        info "bat found: $(command -v bat). ff() previews will use syntax highlighting."
    else
        info "bat not found. ff() falls back to cat with line numbers."
        info "Install it for highlighted previews: https://github.com/sharkdp/bat#installation"
    fi
}


# ─── Bashmarks ────────────────────────────────────────────────────────────────
# Provides s, g, p, d, l commands for saving and jumping to directories.
# https://github.com/huyng/bashmarks

install_bashmarks() {
    header "Bashmarks"

    if [[ -f ~/.local/bin/bashmarks.sh ]]; then
        info "Bashmarks already installed."
        return
    fi

    local tmpdir=""
    trap '[[ -n "$tmpdir" ]] && rm -rf "$tmpdir"' RETURN INT TERM
    tmpdir=$(mktemp -d)

    git clone https://github.com/huyng/bashmarks.git "$tmpdir"
    make -C "$tmpdir" install
    info "Bashmarks installed to ~/.local/bin/bashmarks.sh"

    trap - RETURN INT TERM
}


# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo
    echo "════════════════════════════════════"
    echo "  Dotfiles Installer"
    echo "════════════════════════════════════"

    check_prerequisites
    install_dotfiles
    install_vim_plug
    install_fzf
    install_fd
	install_bashmarks
    install_vifm
    check_bat

    echo
    echo "════════════════════════════════════"
    echo "  Done."
    echo "  Reload your shell:  source ~/.bashrc"
    echo "════════════════════════════════════"
    echo
}

main
