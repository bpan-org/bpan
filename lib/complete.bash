complete:main() (
  n=$COMP_CWORD
  word=${COMP_LINE:0:$COMP_POINT}
  word=${word##*\ }

  if [[ $n -eq 1 ]]; then
    printf '%s\n' "${cmds[@]}" |
      grep "^$word"
  fi
)
