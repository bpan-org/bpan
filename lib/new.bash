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
  if $option_bin; then
    type=bin
  elif $option_lib; then
    type=lib
  else
    error "'$app $cmd' requires --bin or --lib"
  fi

  source-once file
  source-once env

  dir=${1:-.}
  if [[ $dir == . ]]; then
    dir=$(pwd -P)
  fi

  name=${option_name:-$(basename "$dir")}

  [[ $name =~ ^[a-z][-a-z0-9]*$ ]] ||
    error "Illegal package name '$name'"

  mkdir -p "$dir"

  [[ -z $(ls -A "$dir") ]] ||
    error "Directory '$dir' is not empty"

  cd "$dir" || exit

  base=$BPAN_ROOT/share/new
  [[ -d $base ]] || die "'$base' does not exist"

  files=($(
    cd "$base" || exit
    find . -type f -o -type l |
      grep -v '\.sw[po]$' |
      cut -c3- |
      +sort
  ))

  say -g "Creating new BPAN project '$name'"

  for file in "${files[@]}"; do
    from=$base/$file
    to=${file/NAME/$(env:name)}

    if [[ $to == gitignore ]]; then
      to=.gitignore
    fi

    if [[ $type != bin ]]; then
      if [[ $to == .rc ]] ||
         [[ $to == bin/* ]]
      then
        continue
      fi
    fi

    file:copy "$from" "$to"

    if [[ $to == .bpan/config ]]; then
      if [[ $type != bin ]]; then
        text=$(
          cat .bpan/config |
            grep -v '^update = \.rc' |
            grep -v '^ignore = bin/'
        )
        echo "$text" > .bpan/config
      fi
    fi

    if $option_meta &&
      [[ $to == .bpan/config ]]
    then
      mv .bpan/config Meta
      ln -s ../Meta .bpan/config
      say-y "CREATED 'Meta'"

    elif [[ $to == bin/* ]]; then
      chmod +x "$to"
    fi
  done

  git init -q
  say -y "Initialized git repo"

  say -y "Running 'bpan update'"
  if $option_quiet; then
    bpan --quiet update
  else
    bpan update
  fi

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
