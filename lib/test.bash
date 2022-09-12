test:usage() (
  echo "$app [<$app-opts>] $cmd [<$cmd-opts>] [<test-file...>]"
)

test:options() (
  echo "v,verbose   Use 'prove' option '-v'"
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
