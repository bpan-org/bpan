init:options() (
  echo "f,force   Force an action"
)

init:main() (
  share_base=$BPAN_ROOT/share/init
  [[ -d $share_base ]] || die "'$share_base' does not exist"

  files=($(
    cd "$share_base" || exit
    find . -type f -o -type l |
    grep -v '\.sw[po]$' |
    cut -c3- |
      +sort
  ))

  if [[ $* ]]; then
    for file; do
      if [[ ${files[*]} == *$file* ]]; then
        init:copy "$file"
      else
        warn "Ignoring '$file'. Not a BPAN provided file."
      fi
    done
  else
    for file in "${files[@]}"; do
      if $option_force || [[ ! -e $file ]]; then
        init:copy "$file"
      else
        warn "Skipping existing file '$file'. Use --force to override."
      fi
    done
  fi
)

init:copy() (
  file=$1
  dir=$(dirname "$file")

  [[ -e $file ]] && existed=true || existed=false

  [[ $dir == . ]] || mkdir -p "$dir"

  if [[ $file == .bpan/config && -f Meta ]]; then
    meta=$(init:render "$share_base/$file")
    head -n2 <<<"$meta" > "$file"
    echo "${meta/base = ..\/Meta$'\n\n'/}" > Meta
    say-y "UPDATED 'Meta'"
  elif grep -q -E '\(\%.*\%\)' "$share_base/$file"; then
    init:render "$share_base/$file" > "$file"
  else
    cp -pL "$share_base/$file" "$file"
  fi

  if $existed; then
    say-y "UPDATED '$file'"
  else
    say-y "CREATED '$file'"
  fi
)

init:render() (
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
