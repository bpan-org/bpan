setup:options() (
  echo "rc              Used by BPAN's .rc file"
  echo "config          Generate a new '\$BPAN_ROOT/config' file"
  echo "i,interactive   Generate a config interactively"
)

setup:main() (
  config_file=$BPAN_ROOT/config
  local_dir=$BPAN_ROOT/local

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
  +is-cmd-ver perl 5.10 ||
    warn "warning: BPAN requires perl 5.10+ for some operations"

  if ! [[ -d $local_dir ]]; then
    mkdir "$local_dir"
    source-once pkg
    option_quiet=true
    pkg:get-index
  fi

  [[ -f $config_file ]] ||
    setup:new-config-file
)

setup:new-config-file() (
  cd "$BPAN_ROOT" || exit

  source-once file

  touch "$BPAN_ROOT/config"

  option_quiet=true

  file:copy "$BPAN_ROOT/share/setup/config" "$BPAN_ROOT/config"
)
