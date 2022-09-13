config:default() (
  echo --help
)

config:usage() (
  echo "$app [<$app-opts>] $cmd <key> [<value>]"
)

config:options() (
  echo "f,file=   Config file to use"
  echo "l,local   Use './.bpan/config'"
  echo "g,global  Use '\$BPAN_ROOT/config'"
  echo "all       Get all values for a key"
  echo "list      List all keys and values"
)

config:main() (
  files=()
  if [[ ${option_file-} ]]; then
    config_file=$option_file
  elif $option_local; then
    git:assert-in-repo
    config_file=$(git:top-dir)/.bpan/config
  elif $option_global; then
    git:assert-in-repo
    config_file=$BPAN_ROOT/config
  fi

  if $option_list; then
    config:list
  elif [[ $# -eq 1 ]]; then
    config:get "$@"
  elif [[ $# -eq 2 ]]; then
    config:set "$@"
  fi
)
