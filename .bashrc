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

# Detect color support by capability rather than TERM name, so this works for
# xterm-ghostty, foot, wezterm, etc. without maintaining a pattern list.
if [ -x /usr/bin/tput ] && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    color_prompt=yes
fi

if [ "$color_prompt" = yes ]; then
	PS1='\[\e[90m\]╭──[\e[92m\u@\h\e[90m]─[\[\e[33m\]$(short_pwd)\[\e[90m\]]$(j=$(jobs -s | wc -l); [ "$j" -gt 0 ] && printf "─[\[\e[91m\]&%s\[\e[90m\]]" "$j")\n╰─\[\e[97m\]\$ \[\e[0m\]'
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt


# ─── Window title ─────────────────────────────────────────────────────────────
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}:$(short_pwd)\007"'


# ─── Terminal state guard ─────────────────────────────────────────────────────
# fzf's Ctrl-R and Ctrl-T run through `bind -x`, so fzf exits as a foreground job
# while readline still holds the tty raw, and bash keeps that raw state as the
# baseline it restores whenever a later foreground job dies from a signal. After
# an fzf recall, `cat big | reader` whose reader exits early kills cat with
# SIGPIPE and so lands back in raw mode with echo off, making typing invisible.
# Repairing it inside the widget is not possible -- bash never re-preps readline
# afterwards, so leaving the tty cooked there breaks editing for the rest of the
# line -- hence the repair happens here, where the tty is legitimately cooked.
_tty_guard() {
    [[ $- == *i* && -t 0 ]] || return 0
    local s
    s=$(stty -a 2>/dev/null) || return 0
    s=" ${s//[$'\n';]/ } "
    [[ $s == *" -echo "* || $s == *" lnext = <undef> "* ]] && stty sane 2>/dev/null
    return 0
}
PROMPT_COMMAND="_tty_guard${PROMPT_COMMAND:+; $PROMPT_COMMAND}"


# ─── Aliases ──────────────────────────────────────────────────────────────────
alias ll='ls -alF'
alias la='ls -A --classify'

# Colored output
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
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
