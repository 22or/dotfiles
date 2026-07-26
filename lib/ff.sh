# lib/ff.sh — interactive project-wide content search (grep + fzf)

ff() {
  local query="${1:-}"

  # Array for direct invocation; the string form is only for the fzf reload
  # binding below, which a shell re-parses (the query arrives there as
  # "$FZF_QUERY", already quoted).
  local -a grep_args=(
    grep -rIn -E --color=never
    --exclude-dir=.git --exclude-dir=.venv --exclude-dir=node_modules
    --exclude-dir=.idea --exclude-dir=__pycache__ --exclude-dir=.next
    --exclude-dir=.nuxt --exclude-dir=dist --exclude-dir=build --exclude-dir=.cache
    '--exclude=*.png' '--exclude=*.jpg' '--exclude=*.jpeg' '--exclude=*.gif'
    '--exclude=*.webp' '--exclude=*.svg' '--exclude=*.ico' '--exclude=*.woff'
    '--exclude=*.woff2' '--exclude=*.ttf' '--exclude=*.eot' '--exclude=*.pdf'
    '--exclude=*.zip' '--exclude=*.tar' '--exclude=*.gz' '--exclude=*.lock'
  )
  local grep_cmd="${grep_args[*]}"

  local tmp_awk;       tmp_awk=$(mktemp)
  local tmp_query;     tmp_query=$(mktemp)
  local tmp_highlight; tmp_highlight=$(mktemp)
  echo "$query" > "$tmp_query"
  trap "rm -f '$tmp_awk' '$tmp_query' '$tmp_highlight'" RETURN INT TERM

  cat > "$tmp_awk" << 'AWK'
# q comes from the environment, not -v: awk applies string-escape processing to
# -v values, which mangles backslashes in a regex (\. \( \| ...).
BEGIN { q = ENVIRON["q"] }
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
    # q is the same ERE grep matched with, so window and highlight on the real
    # match; a literal substring search misses everything but plain text.
    if (match(content, q)) {
      win   = 40
      start = RSTART - win; if (start < 1) start = 1
      stop  = RSTART + RLENGTH + win - 1
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
  e     = "\033"
  reset = e "[0m"
  bg    = e "[48;5;237m"
  kw    = e "[1;31m"
  q     = ENVIRON["q"]   # see tmp_awk: -v would mangle backslashes
}

# Matching has to happen on the visible text only. bat's output is full of ANSI
# escapes, and a regex run over the raw line can match inside one and corrupt it.

# Split the line into escapes and text: tok[]/isesc[], plus PLAIN, the visible
# characters alone.
function tokenize(s,   n, rest) {
  n = 0
  PLAIN = ""
  rest = s
  while (match(rest, /\033\[[0-9;?]*[a-zA-Z]/)) {
    if (RSTART > 1) {
      n++; tok[n] = substr(rest, 1, RSTART - 1); isesc[n] = 0
      PLAIN = PLAIN tok[n]
    }
    n++; tok[n] = substr(rest, RSTART, RLENGTH); isesc[n] = 1
    rest = substr(rest, RSTART + RLENGTH)
  }
  if (rest != "") { n++; tok[n] = rest; isesc[n] = 0; PLAIN = PLAIN rest }
  return n
}

# Width of the line-number gutter bat ("   6 ") and cat -n ("     6\t") prepend.
# Matching starts after it so the pattern never highlights line numbers, and so
# ^ anchors to the start of the code.
function gutter(s) {
  if (match(s, /^[ ]*[0-9]+[ \t]/)) return RLENGTH
  return 0
}

# Every match of q in PLAIN after the gutter, as visible-character offsets.
function findmatches(from,   n, rest, base) {
  n = 0; base = from; rest = substr(PLAIN, from + 1)
  while (q != "" && rest != "" && match(rest, q)) {
    if (RLENGTH <= 0) break          # empty match would never advance
    n++
    mstart[n] = base + RSTART
    mend[n]   = base + RSTART + RLENGTH - 1
    base += RSTART + RLENGTH - 1
    rest = substr(rest, RSTART + RLENGTH)
  }
  return n
}

# Re-emit the line with q highlighted, every escape bat wrote left intact.
# bar: also paint the line with the match-line background.
function render(s, bar,   ntok, nm, i, j, out, pos, cur, mi, inhl, txt, len) {
  ntok = tokenize(s)
  nm   = findmatches(gutter(PLAIN))
  if (nm == 0 && !bar) return s

  out  = bar ? bg : ""
  pos  = 0    # visible characters emitted so far
  cur  = ""   # SGR state bat has set since its last reset
  mi   = 1
  inhl = 0

  for (i = 1; i <= ntok; i++) {
    if (isesc[i]) {
      out = out tok[i]
      if (tok[i] ~ /^\033\[0?m$/) {         # full reset
        cur = ""
        if (bar) out = out bg
      } else if (tok[i] ~ /^\033\[0;/) {    # reset, then set
        cur = tok[i]
        if (bar) out = out bg
      } else if (tok[i] ~ /m$/) {           # additional SGR
        cur = cur tok[i]
      }
      if (inhl) out = out kw                # bat changed color mid-match
      continue
    }

    txt = tok[i]; len = length(txt)
    for (j = 1; j <= len; j++) {
      pos++
      if (!inhl && mi <= nm && pos == mstart[mi]) { out = out kw; inhl = 1 }
      out = out substr(txt, j, 1)
      if (inhl && pos == mend[mi]) {
        out = out reset cur                 # back to bat's colors
        if (bar) out = out bg
        inhl = 0; mi++
      }
    }
  }

  if (inhl) { out = out reset cur; if (bar) out = out bg }
  if (bar) out = out reset
  return out
}

{ print render($0, NR == hl) }
AWK

  local preview_pos='right:55%'
  [[ ${COLUMNS:-80} -lt 110 ]] && preview_pos='bottom:45%'

  local preview_cmd='
    q=$(cat '"'$tmp_query'"' 2>/dev/null)
    if command -v bat &>/dev/null; then
      bat --style=numbers --color=always --paging=never {1} 2>/dev/null \
        | q="$q" awk -v hl={2} -f '"'$tmp_highlight'"'
    else
      cat -n {1} | q="$q" awk -v hl={2} -f '"'$tmp_highlight'"'
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
      --bind "change:execute-silent(printf '%s' \"\$FZF_QUERY\" > '$tmp_query')+reload:[ -z \"\$FZF_QUERY\" ] && exit 0; $grep_cmd -e \"\$FZF_QUERY\" . 2>/dev/null | q=\"\$FZF_QUERY\" awk -f '$tmp_awk' | grep -v $'^\\\t*\$' || true")
  else
    result=$("${grep_args[@]}" -e "$query" . 2>/dev/null \
      | q="$query" awk -f "$tmp_awk" \
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
