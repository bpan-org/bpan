search:main() (
  if [[ $# -eq 0 ]]; then
    error "No search term provided"
  fi
  term=$(IFS='|'; echo "$*")
  pattern="=.*($term)"

  # shellcheck disable=2207
  found=($(
    git config -l -f "$root/Index" |
      grep -i -E "$pattern" |
      cut -d. -f2 |
      sort |
      uniq || true
  ))

  num=${#found[*]}
  if [[ $num -eq 0 ]]; then
    echo-r "No matches found for search term '$term'"
    return
  elif [[ $num -eq 1 ]]; then
    echo-g "Found 1 matching package:"
  else
    echo-g "Found $num matching packages:"
  fi
  echo

  for pkg in "${found[@]}"; do
    echo-y "* $pkg"
  done
)
