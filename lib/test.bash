test:getopt() {
  getopt_spec="\
$app [<$app-opts>] $command [<cmd-opt...>] [<test-file...>]

'$app $command' Options:
--
v             Use 'prove' option '-v'

h,help        Get help for $command command
"
}

test:main() (
  if [[ $# -eq 0 ]]; then
    [[ -d test ]] ||
      error "Can't test. No 'test/' directory"
    set -- test/*.t
  fi

  if $option_v; then
    set -- -v "$@"
  fi

  prove "$@"
)
