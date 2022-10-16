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
  if [[ ${option_file-} ]]; then
    config=$option_file
  elif $option_local; then
    git:assert-in-repo
    config=$(git:top-dir)/.bpan/config
  elif $option_global; then
    git:assert-in-repo
    config=$BPAN_ROOT/config
  else
    # XXX should we assign this by default?
    config=.bpan/config
  fi

  if $option_list; then
    ini:list --file="$config"
  elif [[ $# -eq 1 ]]; then
    ini:get --file="$config" "$@"
  elif [[ $# -eq 2 ]]; then
    ini:set --file="$config" "$@"
  fi
)
