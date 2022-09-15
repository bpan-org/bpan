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

  source-once env

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
      cut -c3- |
      sort
  ))

  say -g "Creating new BPAN project '$name'"

  for file in "${files[@]}"; do
    new:copy "$file"
  done

  say -y "Running 'bpan update'"
  if $option_quiet; then
    bpan --quiet update
  else
    bpan update
  fi

  git init -q
  say -y "Initialized git repo"

  git add .
  git commit -q -m 'Initial commit'
  say -y "Committed all files to a git 'Initial commit'"

  git branch -M main
  say -y "Set git repo main branch name to 'main'"

  github_id=$(env:github-user-id)
  remote=git@github:$github_id/$name
  git remote add origin "$remote"
  say -y "Set git repo remote to '$remote'"

  say -g "Created new BPAN project '$name'"
)

# TODO move following functions to lib/file.bash
new:copy() (
  file=$1
  dir=$(dirname "$file")

  [[ -e $file ]] && existed=true || existed=false

  [[ $dir == . ]] || mkdir -p "$dir"

  from=$share_base/$file
  to=${file/NAME/$name}

  if [[ $type != bin ]]; then
    if [[ $file == .rc ]] ||
       [[ $file == bin/NAME ]]
    then
      return
    fi
  fi

  if grep -q -E '\(\%.*\%\)' "$from"; then
    new:render "$from" > "$to"
  else
    cp -pL "$from" "$to"
  fi

  if [[ $type != bin ]]; then
    text=$(
      cat .bpan/config |
        grep -v '^update = \.rc' |
        grep -v '^ignore = bin/'
    )
    echo "$text" > .bpan/config
  fi

  if $option_meta &&
     [[ $file == .bpan/config ]]
  then
    mv .bpan/config Meta
    ln -s ../Meta .bpan/config
    say-y "CREATED 'Meta'"

  elif [[ $file == bin/NAME ]]; then
    chmod +x "$to"

  elif [[ $file == doc/NAME.md ]]; then
    ln -s "$to" ReadMe.md
    say-y "CREATED 'ReadMe.md'"

  elif [[ $file == gitignore ]]; then
    mv gitignore .gitignore
    to=.gitignore
  fi

  say-y "CREATED '$to'"
)

new:render() (
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
