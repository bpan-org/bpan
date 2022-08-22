config:getopt() {
  getopt_default_help=true
  getopt_spec="\
$app [<$app-opts>] $command <key> [<value>]

'$app $command' Options:
--
f,file=       Config file to use
s,system      Use system config file

h,help        Get help for $command command
"
}

config:main() (
  config_file=${option_file-}
  if ! [[ $config_file ]]; then
    if [[ -f .bpan/config ]]; then
      config_file=.bpan/config
    else
      config_file=~/.bpan/config
    fi
  fi

  bpan:config "$@"
)
