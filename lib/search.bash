search:main() (
  if [[ $# -eq 0 ]]; then
    error "No search term provided"
  fi
  term=$(IFS='|'; echo "$*")
  pattern="=.*($term)"

  # shellcheck disable=2207
  found=($(
    git config -l -f "$index_file" |
      grep -i -E "$pattern" |
      cut -d. -f2 |
      +sort |
      uniq || true
  ))

  num=${#found[*]}
  if [[ $num -eq 0 ]]; then
    say-r "No matches found for search term '$term'"
    return
  elif [[ $num -eq 1 ]]; then
    say-g "Found 1 matching package:"
  else
    say-g "Found $num matching packages:"
  fi
  echo

  for package in "${found[@]}"; do
    say-y "* $package"
  done
)
