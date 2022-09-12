complete:main() (
  word=${COMP_LINE:0:$COMP_POINT}
  word=${word##*\ }

  if [[ $COMP_CWORD -eq 1 ]]; then
    printf '%s\n' "${getopt_cmds[@]}" |
      grep "^$word"
  fi
)
