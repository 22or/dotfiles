# ─── Editor ───────────────────────────────────────────────────────────────────
export EDITOR=vim

# PATH + libraries from ~/dotfiles/install.sh (~/.local/bin, fzf, vifm apt extracts)
[[ -f "$HOME/.local/share/dotfiles/env.sh" ]] && . "$HOME/.local/share/dotfiles/env.sh"


# ─── Prompt ───────────────────────────────────────────────────────────────────
# Falls back to plain user@host:path$ if terminal has no color support.

short_pwd() {
    local pwd="$(pwd)"
    local max=40

    pwd="${pwd/#$HOME/\~}"
    local len=${#pwd}

    if (( len > max )); then
        local front=10
        local back=$((max - front - 3))
        printf "%s...%s" "${pwd:0:front}" "${pwd:len-back}"
    else
        printf "%s" "$pwd"
    fi
}

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes ;;
esac

if [ "$color_prompt" = yes ]; then
	PS1='\[\e[90m\]╭──[\e[92m\u@\h\e[90m]─[\[\e[33m\]$(short_pwd)\[\e[90m\]]$(j=$(jobs -s | wc -l); [ "$j" -gt 0 ] && printf "─[\[\e[91m\]&%s\[\e[90m\]]" "$j")\n╰─\[\e[97m\]\$ \[\e[0m\]'
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt


# ─── Window title ─────────────────────────────────────────────────────────────
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}:$(short_pwd)\007"'


# ─── Aliases ──────────────────────────────────────────────────────────────────
alias ll='ls -alF'
alias la='ls -A --classify'

# Colored output
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


# ─── fzf ──────────────────────────────────────────────────────────────────────
if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
elif [[ -f ~/.fzf/shell/key-bindings.bash ]]; then
    source ~/.fzf/shell/key-bindings.bash
fi

export FZF_DEFAULT_COMMAND="fdfind . --hidden"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fdfind -t d . $HOME"


# ─── File content find ───────────────────────────────────────────────────────
[[ -f "${BASH_SOURCE[0]%/*}/lib/ff.sh" ]] && source "${BASH_SOURCE[0]%/*}/lib/ff.sh"


# ─── Bashmarks ────────────────────────────────────────────────────────────────
[[ -f "$HOME/.local/bin/bashmarks.sh" ]] && \
    source "$HOME/.local/bin/bashmarks.sh"
