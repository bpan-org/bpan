new:main() (
  [[ $# -eq 1 ]] ||
    error "'$app new' requires a directory name argument"

  name=$1
  dir=$name

  if [[ -d $dir ]]; then
    cd "$dir" || exit
    if [[ $(ls -A .) ]]; then
      error "Directory '$dir' is not empty"
    fi
  else
    mkdir "$dir"
    cd "$dir" || exit
  fi

  option_force=false
  source-once init

  init:main
)
