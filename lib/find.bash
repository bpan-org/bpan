find:default() ( echo '--help' )
find:usage() ( echo "$app [<$app-opts>] $cmd <$cmd-term-regexp>" )

find:options() (cat <<...
i,installed   List installed packages

U,update      Update index(es)
I,index=      Index name to find
...
)

find:main() (
  if $option_installed; then
    find:list-installed "$@"
    return
  fi

  [[ -t 1 ]] && tty=true || tty=false

  if [[ $# -eq 0 ]]; then
    error "No search term provided"
  fi
  term=$(IFS='|'; echo "$*")
  pattern=".*($term)"

  source-once util/db

  force_update=$option_update \
    db:sync

  results=$(db:find-packages "$pattern")
  IFS=$'\n' read -d '' -r -a found < <(echo "$results") || true

  num=${#found[*]}
  if [[ $num -eq 0 ]]; then
    $tty && say -r "No matches found for search term '$term'"
  elif [[ $num -eq 1 ]]; then
    $tty && say -g "Found 1 matching package:"
  else
    $tty && say -g "Found $num matching packages:"
  fi

  for package in "${found[@]}"; do
    if $tty; then
      say -y "* $package"
    else
      echo "$package"
    fi
  done
)

find:list-installed() (
  source-once util/db

  if [[ ! -d $install_dir/src ]]; then
    say -r "No BPAN packages currently installed"
    return
  fi

  read -r -a installed <<<"$(db:list-installed)"

  if [[ ${#installed[*]} -eq 0 ]]; then
    say -r "No BPAN packages currently installed"
    return
  fi

  for id in "${installed[@]}"; do
    if db:package-is-primary "$id"; then
      say -g "* $id"
    else
      say -y "  $id"
    fi

    if $option_verbose; then
      list:links "$id"
    fi
  done
)
