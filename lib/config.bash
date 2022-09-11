config:getopt() (
  echo "\
getopt_default=--help

$app [<$app-opts>] $cmd <key> [<value>]

'$app $cmd' Options:
--
f,file=       Config file to use
s,system      Use system config file

h,help        Get help for $cmd command
"
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
