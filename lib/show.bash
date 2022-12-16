show:options() (cat <<...
cmds          List $app commands

q,quiet       Print only the command names
...
)

show:main() (
  if $option_cmds; then
    show:cmds
  else
    bpan-run show --help
  fi
)

show:cmds() (
  i=1

  while read -r name desc; do
    if $option_quiet; then
      echo "$name"
    else
      printf '%2d) %-10s - %s\n' $((i++)) "$name" "$desc"
    fi
  done <<<"$(grep -E '^  \w+  ' <<<"$getopt_spec")"
)
