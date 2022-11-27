search:default() ( echo '--help' )
search:usage() ( echo "$app [<$app-opts>] $cmd <$cmd-term-regexp>" )
search:usage() ( echo "$app [<$app-opts>] $cmd <$cmd-term-regexp>" )

search:options() (cat <<...
U,update  Update index(es)
I,index=  Index name to search
...
)

search:main() (
  [[ -t 1 ]] && tty=true || tty=false

  if [[ $# -eq 0 ]]; then
    error "No search term provided"
  fi
  term=$(IFS='|'; echo "$*")
  pattern="=.*($term)"

  source-once util/db

  force_update=$option_update \
    db:sync

  found=$(db:find-packages "$pattern")

  num=$(wc -l <<<"$found")
  if [[ $num -eq 0 ]]; then
    $tty && say -r "No matches found for search term '$term'"
    return
  elif [[ $num -eq 1 ]]; then
    $tty && say -g "Found 1 matching package:"
  else
    $tty && say -g "Found $num matching packages:"
  fi
  echo

  while read -r package; do
    if $tty; then
      say -y "* $package"
    else
      echo "$package"
    fi
  done <<<"$found"
)
