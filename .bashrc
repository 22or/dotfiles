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

export FZF_DEFAULT_COMMAND="fdfind . --hidden"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fdfind -t d . $HOME"


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
	echo
}


# ─── File content find ───────────────────────────────────────────────────────
ff() {
  local query="${1:-}"

  local grep_cmd="grep -rIn --color=never \
    --exclude-dir=.git --exclude-dir=.venv --exclude-dir=node_modules \
    --exclude-dir=.idea --exclude-dir=__pycache__ --exclude-dir=.next \
    --exclude-dir=.nuxt --exclude-dir=dist --exclude-dir=build --exclude-dir=.cache \
    --exclude=*.png --exclude=*.jpg --exclude=*.jpeg --exclude=*.gif \
    --exclude=*.webp --exclude=*.svg --exclude=*.ico --exclude=*.woff \
    --exclude=*.woff2 --exclude=*.ttf --exclude=*.eot --exclude=*.pdf \
    --exclude=*.zip --exclude=*.tar --exclude=*.gz --exclude=*.lock"

  local tmp_awk;       tmp_awk=$(mktemp /tmp/ff_awk.XXXX)
  local tmp_query;     tmp_query=$(mktemp /tmp/ff_query.XXXX)
  local tmp_highlight; tmp_highlight=$(mktemp /tmp/ff_hl.XXXX)
  echo "$query" > "$tmp_query"
  trap "rm -f '$tmp_awk' '$tmp_query' '$tmp_highlight'" RETURN INT TERM

  cat > "$tmp_awk" << 'AWK'
{
  colon1 = index($0, ":")
  if (colon1 == 0) next

  path = substr($0, 1, colon1 - 1)
  rest = substr($0, colon1 + 1)

  colon2 = index(rest, ":")
  if (colon2 == 0) next

  line    = substr(rest, 1, colon2 - 1)
  content = substr(rest, colon2 + 1)

  if (line !~ /^[0-9]+$/) next

  gsub(/\t/, "    ", content)

  stripped = content
  gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", stripped)
  if (stripped == "") next

  n = split(path, p, "/")
  short = (n > 2) ? "…/" p[n-1] "/" p[n] : path

  display_content = content
  if (q != "") {
    match_pos = index(tolower(content), tolower(q))
    if (match_pos > 0) {
      win   = 40
      start = match_pos - win; if (start < 1) start = 1
      stop  = match_pos + length(q) + win - 1
      display_content = (start > 1 ? "…" : "") \
                        substr(content, start, stop - start + 1) \
                        (stop < length(content) ? "…" : "")
    }
    gsub(q, "\033[1;31m&\033[0m", display_content)
  }

  printf "%s\t%s\t\033[36m%s\033[0m:\033[33m%s\033[0m: %s\n", path, line, short, line, display_content
}
AWK

  cat > "$tmp_highlight" << 'AWK'
BEGIN {
  e    = "\033"
  bg   = e "[48;5;237m"
  reset = e "[0m"
  kw   = e "[1;31m"
}
NR == hl {
  # Strip ALL ANSI escape sequences for a clean slate
  gsub(/\033\[[0-9;]*[mKHfABCDsuJh]/, "")
  # Keyword highlight on clean text, keeping background intact after each reset
  if (q != "") gsub(q, kw "&" reset bg)
  print bg $0 reset
  next
}
{
  # Other lines: keep bat syntax colors, best-effort keyword highlight
  if (q != "") gsub(q, kw "&" reset)
  print
}
AWK

  local preview_pos='right:55%'
  [[ ${COLUMNS:-80} -lt 110 ]] && preview_pos='bottom:45%'

  local preview_cmd='
    q=$(cat '"'$tmp_query'"' 2>/dev/null)
    if command -v bat &>/dev/null; then
      bat --style=numbers --color=always --paging=never {1} 2>/dev/null \
        | awk -v hl={2} -v q="$q" -f '"'$tmp_highlight'"'
    else
      cat -n {1} | awk -v hl={2} -v q="$q" -f '"'$tmp_highlight'"'
    fi
  '

  local fzf_opts=(
    --ansi
    --delimiter $'\t'
    --with-nth 3
    --preview "$preview_cmd"
    --preview-window "${preview_pos}:+{2}-/2:wrap"
    --bind 'ctrl-p:toggle-preview'
    --header '  ENTER open  │  CTRL-P toggle preview'
  )

  local result

  if [[ -z "$query" ]]; then
    result=$(fzf "${fzf_opts[@]}" \
      --disabled \
      --prompt '  ' \
      --bind "change:execute-silent(echo {q} > '$tmp_query')+reload:$grep_cmd {q} . 2>/dev/null | awk -v q={q} -f '$tmp_awk' | grep -v $'^\\\t*\$' || true")
  else
    result=$(eval "$grep_cmd '$query' ." 2>/dev/null \
      | awk -v q="$query" -f "$tmp_awk" \
      | grep -v $'^\t*$' \
      | fzf "${fzf_opts[@]}" --prompt "  $query > ")
  fi

  if [[ -n "$result" ]]; then
    local file line
    file=$(cut -f1 <<< "$result")
    line=$(cut -f2 <<< "$result")
    ${EDITOR:-vim} +"$line" "$file"
  fi
}


# ─── Bashmarks ────────────────────────────────────────────────────────────────
# ─── Bashmarks ────────────────────────────────────────────────────────────────
[[ -f "$HOME/.local/bin/bashmarks.sh" ]] && \
    source "$HOME/.local/bin/bashmarks.sh"
