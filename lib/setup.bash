setup:main() (
  config=$root/config
  local_dir=$root/local

  (
    ini:init "$root/.bpan/config"
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
  conf_file=$root/config

  if [[ -f $conf_file ]] &&
     ! $option_force
  then
    error "Won't overwrite existing BPAN config file '$conf_file'."
  fi

  source-once add

  touch "$root/config"

  option_quiet=true

  add:file-copy "$root/share/setup/config" "$root/config"
)
