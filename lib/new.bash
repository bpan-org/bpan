new:usage() (
  echo "$app [<opts>] $cmd <$cmd-opts> [<path>]"
)

new:options() (
  echo "n,name=   Name to use for the package"
  echo "b,bin     Create a new bin (binary) package"
  echo "l,lib     Create a new lib (library) package"
  echo "M,meta    Use 'Meta' as config file"
)

new:main() (
  [[ $# -eq 1 ]] ||
    error "'$app new' requires a directory name argument"

  if $option_bin; then
    type=bin
  elif $option_lib; then
    type=lib
  else
    error "'$app $cmd' requires --bin or --lib"
  fi

  dir=$1
  [[ $dir == . ]] && name=$(pwd -P)

  name=${option_name:-$(basename "$dir")}

  [[ $name =~ ^[a-z][-a-z0-9]*$ ]] ||
    error "Illegal package name '$name'"

  mkdir -p "$dir"

  [[ -z $(ls -A "$dir") ]] ||
    error "Directory '$dir' is not empty"

  cd "$dir" || exit

  share_base=$BPAN_ROOT/share/new
  [[ -d $share_base ]] || die "'$share_base' does not exist"

  files=($(
    cd "$share_base" || exit
    find . -type f -o -type l |
    grep -v '\.sw[po]$' |
    grep -v config |
    cut -c3- |
      sort
  ))

  set -- .bpan/config "${files[@]}"

  for file; do
    new:copy "$file"
  done

  say -y "Running 'bpan update'"
  bpan update

  git init -q
  say -y "Initialized git repo"

  # TODO add git remote here…

  git add .
  git commit -q -m 'Initial commit'
  say -g "Committed all files to a git 'Initial commit'"
)

new:copy() (
  file=$1
  dir=$(dirname "$file")

  [[ -e $file ]] && existed=true || existed=false

  [[ $dir == . ]] || mkdir -p "$dir"

  from=$share_base/$file
  to=${file/NAME/$name}

  if grep -q -E '\(\%.*\%\)' "$from"; then
    new:render "$from" > "$to"
  else
    cp -pL "$from" "$to"
  fi

  if $option_meta && [[ $from == */.bpan/config ]]; then
    mv .bpan/config Meta
    ln -s ../Meta .bpan/config
    say-y "CREATED 'Meta'"

  elif [[ $from == */bin/NAME ]]; then
    chmod +x "$to"

  elif [[ $from == */doc/NAME.md ]]; then
    ln -s "$from" ReadMe.md
    say-y "CREATED 'ReadMe.md'"

  elif [[ $from == */gitignore ]]; then
    mv gitignore .gitignore
    to=.gitignore
  fi

  say-y "CREATED '$to'"
)

new:render() (
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
