test:usage() (
  echo "$app [<$app-opts>] $cmd [<$cmd-opts>] [<test-file...>]"
  echo "$app [<$app-opts>] $cmd --renumber"
)

test:options() (
  echo "v,verbose   Use 'prove' option '-v'"
  echo "renumber    Renumber the test/*.t files"
)

test:main() (
  if $option_renumber; then
    test:renumber
    return
  fi

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

test:renumber() (
  git:in-repo ||
    error "Can't --renumber, not in a package repo"

  top=$(git:top-dir)

  cd "$top" || die

  [[ -d test ]] ||
    error "Can't --renumber, no directory '$top/test/'"

  cd test || die

  tests=($(
    shopt -s nullglob
    printf '%s\n' *.t |
      +sort
  ))

  [[ ${#tests[*]} -gt 0 ]] ||
    error "No test/*.t files found to --renumber"

  ii=0
  for file in "${tests[@]}"; do
    if [[ $file == 00-* ]]; then
      say -y "Leaving '$file'"
    else
      (( ++ii ))
      if [[ $file =~ ^[0-9]{2}-(.+) ]]; then
        printf -v nfile '%02d-%s' "$ii" "${BASH_REMATCH[1]}"
        if [[ $file == "$nfile" ]]; then
          say -y "Leaving '$file'"
        else
          say -y "Moving  '$file' -> '$nfile'"
          (
            $option_verbose && set -x
            git mv "$file" "$nfile"
          )
        fi
      fi
    fi
  done
)
