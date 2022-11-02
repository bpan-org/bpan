search:default() ( echo '--help' )
search:usage() ( echo "$app [<$app-opts>] $cmd <$cmd-term-regexp>" )

search:main() (
  [[ -t 1 ]] && tty=true || tty=false

  if [[ $# -eq 0 ]]; then
    error "No search term provided"
  fi
  term=$(IFS='|'; echo "$*")
  pattern="=.*($term)"

  if [[ ! -f $bpan_index_file ]]; then
    source-once util/pkg
    pkg:index-update
  fi

  # shellcheck disable=2207
  found=($(
    git config -l -f "$bpan_index_file" |
      grep -i -E "$pattern" |
      grep '^package\.' |
      cut -d. -f2 |
      +l:sort |
      uniq || true
  ))

  num=${#found[*]}
  if [[ $num -eq 0 ]]; then
    $tty && say -r "No matches found for search term '$term'"
    return
  elif [[ $num -eq 1 ]]; then
    $tty && say -g "Found 1 matching package:"
  else
    $tty && say -g "Found $num matching packages:"
  fi
  echo

  for package in "${found[@]}"; do
    if $tty; then
      say -y "* $package"
    else
      echo "$package"
    fi
  done
)
