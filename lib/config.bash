config:default() (
  echo --help
)

config:usage() (
  echo "$app [<$app-opts>] $cmd <key> [<value>]"
)

config:options() (
  echo "f,file=       Config file to use"
  echo "s,system      Use system config file"
)

config:main() (
  config_file=${option_file-}
  if ! [[ $config_file ]]; then
    if [[ -f .bpan/config ]]; then
      config_file=.bpan/config
    else
      config_file=~/.bpan/config
    fi
  fi
  config_file=$(readlink -f "$config_file")
  config=$(< "$config_file")

  bpan:config "$@"
)
