setup:options() (
  echo "rc              Used by BPAN's .rc file"
  echo "config          Generate a new '\$BPAN_ROOT/config' file"
  echo "f,force         Overwrite existing files"
)

setup:main() (
  config_file=$BPAN_ROOT/config
  local_dir=$BPAN_ROOT/local

  if $option_rc; then
    setup:rc "$@"
  elif $option_config; then
    setup:new-config-file
  else
    error "--config or --interactive is required"
  fi
)

setup:rc() (
  config_file=$BPAN_ROOT/.bpan/config \
    bpan:require-commands ||
      +warn "Please install missing BPAN requirements above"

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
  conf_file=$BPAN_ROOT/config

  if [[ -f $conf_file ]] &&
     ! $option_force
  then
    error "Won't overwrite existing BPAN config file '$conf_file'."
  fi

  source-once file

  touch "$BPAN_ROOT/config"

  option_quiet=true

  file:copy "$BPAN_ROOT/share/setup/config" "$BPAN_ROOT/config"
)
