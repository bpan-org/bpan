file:default() (
  echo --help
)

file:usage() (
  echo "$app <opts> $cmd <file-to-update...>"
  echo "$app $cmd --list"
)

file:options() (
  echo "l,list  List files that can be used"
)

file:main() (
  share_base=$BPAN_ROOT/share/file

  if $option_list; then
    file:list
    return
  fi

  [[ -d .git ]] ||
    error "Must be in root directory of repo"

  for file; do
    from=$BPAN_ROOT/share/file/$file
    if [[ -f $from ]]; then
      file:copy "$file"
    else
      say -r "WARNING '$from' - no such file"
    fi
  done
)

file:list() (
  cd "$share_base" || exit
  find . -type f -o -type l |
    cut -c3- |
    sort
)

file:copy() (
  file=$1
  dir=$(dirname "$file")
  temp=$(mktemp)

  mkdir -p "$dir"

  if grep -q -E '\(\%.*\%\)' "$share_base/$file"; then
    file:render "$share_base/$file" > "$temp"
  else
    cp -pL "$share_base/$file" "$temp"
  fi

  if [[ -e $file ]]; then
    if diff -q >/dev/null "$file" "$temp"; then
      rm -f "$temp"
      say-g "CURRENT '$file'"
    else
      mv "$temp" "$file"
      say-y "UPDATED '$file'"
    fi
  else
    mv "$temp" "$file"
    say-y "CREATED '$file'"
  fi
)

file:render() (
  source-once env

  text=$(< "$1")

  while [[ $text =~ \(%(\ *[-a-z0-9]+\ *)%\) ]]; do
    match=${BASH_REMATCH[1]}
    cmd=${match##\ }
    cmd=${cmd%%\ }

    text=${text/\(%$match%\)/$("env:$cmd")}
  done

  echo "$text"
)
