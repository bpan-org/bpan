#FISH
test -n "$FISH_VERSION" && eval '
set -l cmds (bpan --complete)
complete -f \
  -c bpan \
  -n "not __fish_seen_subcommand_from $cmds" \
  -a "$cmds"
exit
'
#/FISH

if type complete &>/dev/null; then
  _bpan_completion() {
    local words cword
    if type _get_comp_words_by_ref &>/dev/null; then
      _get_comp_words_by_ref -n = -n @ -n : -w words -i cword
    else
      cword=$COMP_CWORD
      words=("${COMP_WORDS[@]}")
    fi

    COMPREPLY=($(
      IFS=$'\n' \
      COMP_CWORD=$cword \
      COMP_LINE=$COMP_LINE \
      COMP_POINT=$COMP_POINT \
      bpan --complete -- "${words[@]}" \
        2>/dev/null
    )) || return

    if type __ltrim_colon_completions &>/dev/null; then
      __ltrim_colon_completions "${words[cword]}"
    fi
  }
  complete -o default -F _bpan_completion bpan

elif type compdef &>/dev/null; then
  _bpan_completion() {
    compadd -- $(
      si=$IFS
      COMP_CWORD=$((CURRENT-1)) \
      COMP_LINE=$BUFFER \
      COMP_POINT=0 \
      bpan --complete -- "${words[@]}" \
        2>/dev/null
    )
  }
  compdef _bpan_completion bpan

elif type compctl &>/dev/null; then
  _bpan_completion() {
    local cword line point words si
    read -rAc words
    read -rcn cword
    let cword-=1
    read -rl line
    read -rln point
    reply=($(
      IFS=
      COMP_CWORD="$cword" \
      COMP_LINE="$line" \
      COMP_POINT="$point" \
      bpan --complete -- "${words[@]}" \
        2>/dev/null
    )) || return
  }
  compctl -K _bpan_completion bpan
fi
