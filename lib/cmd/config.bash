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
  opts=()

  if [[ ${option_file-} ]]; then
    opts+=(--file="$option_file")
  elif $option_local; then
    +git:in-repo || error \
      "'bpan config --local' can only be used inside a BPAN package repo"
    opts+=(--file="$(+git:top-dir)"/.bpan/config)
  elif $option_global; then
    opts+=(--file="$root"/config)
  fi

  if $option_list; then
    ini:list "${opts[@]}"
  elif [[ $# -eq 1 ]]; then
    ini:get "${opts[@]}" "$@"
  elif [[ $# -eq 2 ]]; then
    ini:set "${opts[@]}" "$@"
  fi
)
