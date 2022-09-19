bpan:require-commands() (
  ok=true
  while read -r line; do
    [[ $line ]] || break
    command=${line#require.command.}
    version=${command#*=}
    version=${version%+}
    command=${command%%=*}
    if [[ $version == '0' ]]; then
      +is-cmd "$command" || {
        ok=false
        if ! ${option_quiet:-false}; then
          echo "warning: command '$command' is required"
        fi
      }
    else
      +is-cmd-ver "$command" "$version" || {
        ok=false
        if ! ${option_quiet:-false}; then
          echo "warning: command '$command' v$version or higher is required"
        fi
      }
    fi
  done < <(
    config:list |
      grep "^require\.command\."
  )

  "$ok"
)
