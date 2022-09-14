bpan:require-commands() (
  while read -r line; do
    [[ $line ]] || break
    command=${line#require.commands.}
    version=${command#*=}
    version=${version%+}
    command=${command%%=*}
    require-command-version "$command" "$version"
  done < <(
    git config -lf- <<<"$config" |
      grep "^require\.command\."
  )
)
