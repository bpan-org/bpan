ini:match() (
  set "${INI_DEBUG_BASH_X:-+x}"
  ini:data "$@"
  [[ ${#args[*]} -eq 1 ]] ||
    ini:die "ini:all requires 1 key"
  git config --file <(cat "${__ini_files[@]?}") --get-regexp "${args[@]}"
)

ini:first() (
  set "${INI_DEBUG_BASH_X:-+x}"
  read -r key value < <(ini:match "$@")
  [[ $value ]] || return
  echo "$value"
)

ini:first-key() (
  set "${INI_DEBUG_BASH_X:-+x}"
  read -r key value < <(ini:match "$@")
  [[ $key ]] || return
  echo "$key"
)

+git:commit-sha512() (
  ref=${1:-HEAD}
  {
    printf 'commit %s\0' "$(
      git --no-replace-objects cat-file commit "$ref" | wc -c
    )"
    git cat-file commit HEAD
  } |
    sha512sum |
    cut -d' ' -f1
)

bpan:require-commands() (
  ok=true
  while read -r line; do
    [[ $line ]] || break
    command=${line#require.command.}
    version=${command#*=}
    version=${version%+}
    command=${command%%=*}
    if [[ $version == '0' ]]; then
      +cmd:ok "$command" || {
        ok=false
        if ! ${option_quiet:-false}; then
          echo "warning: command '$command' is required"
        fi
      }
    else
      +cmd:ok-ver "$command" "$version" || {
        ok=false
        if ! ${option_quiet:-false}; then
          echo "warning: command '$command' v$version or higher is required"
        fi
      }
    fi
  done < <(
    ini:list |
      grep "^require\.command\."
  )

  "$ok"
)
