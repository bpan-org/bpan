setup:main() (
  config=$BPAN_ROOT/config
  local_dir=$BPAN_ROOT/local

  (
    ini:init "$BPAN_ROOT/.bpan/config"
    bpan:require-commands ||
      warn "Please install missing BPAN requirements above"
  )

  if ! [[ -d $local_dir ]]; then
    mkdir "$local_dir"
    source-once pkg
    option_quiet=true
    pkg:index-update
  fi

  [[ -f $config ]] ||
    setup:new-config-file
)

setup:new-config-file() (
  conf_file=$BPAN_ROOT/config

  if [[ -f $conf_file ]] &&
     ! $option_force
  then
    error "Won't overwrite existing BPAN config file '$conf_file'."
  fi

  source-once add

  touch "$BPAN_ROOT/config"

  option_quiet=true

  add:file-copy "$BPAN_ROOT/share/setup/config" "$BPAN_ROOT/config"
)
