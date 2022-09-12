cmds:options() (
  echo "q,quiet       Print only the command names"
)

cmds:main() (
  i=1
  names=()
  descs=()

  while read -r name desc; do
    if $option_quiet; then
      echo "$name"
    else
      printf '%2d) %-10s - %s\n' $((i++)) "$name" "$desc"
    fi
  done <<<"$(grep -E '^  \w+  ' <<<"$getopt_spec")"
)
