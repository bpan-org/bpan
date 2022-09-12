complete:main() (
  if [[ $BPAN_SHELL == bash || $BPAN_SHELL == zsh ]]; then
    word=${COMP_LINE:0:$COMP_POINT}
    word=${word##*\ }

    if [[ $COMP_CWORD -eq 1 ]]; then
      printf '%s\n' "${getopt_cmds[@]}" |
        grep "^$word"
    fi

  elif [[ $BPAN_SHELL == fish ]]; then
    complete:fish "$@"
  fi
)

complete:fish() (
  printf '%s\n' "${getopt_cmds[@]}"
)
