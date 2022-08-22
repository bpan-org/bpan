test:main() (
  if [[ $# -eq 0 ]]; then
    [[ -d test ]] ||
      error "Can't test. No 'test/' directory"
    set -- -v test/*.t
  fi

  $option_verbose && set -x

  prove "$@"
)
