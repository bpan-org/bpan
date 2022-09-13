setup:options() (
  echo "rc              Used by BPAN's .rc file"
  echo "config          Generate a new '\$BPAN_ROOT/config' file"
  echo "i,interactive   Generate a config interactively"
)

setup:main() (
  config_file=$BPAN_ROOT/config

  if $option_rc; then
    setup:rc "$@"
  elif $option_interactive; then
    error "--interactive not yet implemented"
  elif $option_config; then
    setup:new-config-file
  else
    error "--config or --interactive is required"
  fi
)

setup:rc() (
  [[ -f $config_file ]] ||
    setup:new-config-file

  true
)

setup:new-config-file() (
  cd "$BPAN_ROOT" || exit
  bpan file --type=setup config
)
