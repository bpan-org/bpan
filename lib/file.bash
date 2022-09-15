file:copy() (
  from=$1
  to=$2

  [[ -e $to ]] &&
    action=UPDATED ||
    action=CREATED

  dir=$(dirname "$to")

  [[ -e $to ]] && existed=true || existed=false

  [[ $dir == . ]] || mkdir -p "$dir"

  temp=$(mktemp)

  if grep -q -E '\(\%.*\%\)' "$from"; then
    file:render "$from" > "$temp"
  else
    cp -pL "$from" "$temp"
  fi

  if [[ -e $to ]]; then
    if diff -q "$to" "$temp" &>/dev/null; then
      rm -f "$temp"
      action=CURRENT
    else
      mv "$temp" "$to"
    fi

  else
    mv "$temp" "$to"
  fi

  say-y "$action '$to'"
)

file:render() (
  source-once env

  text=$(< "$1")

  while [[ $text =~ \(%(\ *[-a-zA-Z0-9]+\ *)%\) ]]; do
    match=${BASH_REMATCH[1]}
    cmd=${match##\ }
    cmd=${cmd%%\ }

    text=${text/\(%$match%\)/$("env:$cmd")}
  done

  echo "$text"
)
