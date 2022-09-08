cmds:getopt() (
  echo "\
getopt_default=()
$app [<$app-opts>] $cmd <key> [<value>]

'$app $cmd' Options:
--
q,quiet       Print only the command names

h,help        Get help for $cmd command
"
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
