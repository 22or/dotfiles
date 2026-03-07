# ─── Editor ───────────────────────────────────────────────────────────────────
export EDITOR=vim


# ─── Prompt ───────────────────────────────────────────────────────────────────
# Falls back to plain user@host:path$ if terminal has no color support.

short_pwd() {
    local pwd="$(pwd)"
    local max=60

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
    PS1='\[\e[90m\]╭──[\e[092m\u@\h\e[90m]─[\[\e[33m\]$(short_pwd)\[\e[90m\]]─[\[\e[94m\]\t\[\e[90m\]]\n╰─\[\e[97m\]\$ \[\e[0m\]'
else
    PS1='\u@\h:\w\$ '
fi
unset color_prompt


# ─── Window title ─────────────────────────────────────────────────────────────
PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}:$(short_pwd)\007"'


# ─── Aliases ──────────────────────────────────────────────────────────────────
alias ll='ls -alF'
alias la='ls -A --classify'
alias l='ls -CF'

# Colored output
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


# ─── fzf ──────────────────────────────────────────────────────────────────────
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && \
    source /usr/share/doc/fzf/examples/key-bindings.bash

export FZF_DEFAULT_COMMAND="fd . --hidden"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd -t d . $HOME"


# ─── C++ helper ───────────────────────────────────────────────────────────────
# Usage: run <file.cpp> [extra g++ flags]
run() {
    if [ -z "$1" ]; then
        echo "Usage: run <file.cpp> [extra g++ flags]"
        return 1
    fi

    local src="$1" base="${1%.*}"
    shift

    trap 'rm -f "$base"' RETURN INT TERM

    g++ -std=c++17 -O2 "$src" -o "$base" "$@" || { echo "Compilation failed."; return 1; }
    "./$base"
}
