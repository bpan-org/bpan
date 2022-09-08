test:getopt() (
  echo "\
$app [<$app-opts>] $cmd [<cmd-opt...>] [<test-file...>]

'$app $cmd' Options:
--
v,verbose     Use 'prove' option '-v'

h,help        Get help for $cmd command
"
)

test:main() (
  if [[ $# -eq 0 ]]; then
    [[ -d test ]] ||
      error "Can't test. No 'test/' directory"
    set -- test/*.t
  fi

  if $option_verbose; then
    set -- -v "$@"
  fi

  prove "$@"
)
