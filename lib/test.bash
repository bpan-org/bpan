test:usage() (
  echo "$app [<$app-opts>] $cmd [<$cmd-opts>] [<test-file...>]"
  echo "$app [<$app-opts>] $cmd --renumber"
)

test:options() (
  echo "v,verbose   Use 'prove' option '-v'"
  echo "b,bash=     Bash version to test with"
  echo "renumber    Renumber the test/*.t files"
)

test:main() (
  if $option_renumber; then
    test:renumber
    return
  elif [[ $option_bash ]]; then
    test:test-in-docker "$@"
    return
  fi

  if [[ ! $* ]]; then
    [[ -d test ]] ||
      error "Can't test. No 'test/' directory"
    set -- test/*.t
  fi

  if $option_verbose; then
    set -- -v "$@"
  fi

  if $option_quiet; then
    prove "$@" &>/dev/null
  else
    prove "$@"
  fi
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
    if [[ $file == 00-* ]] ||
       [[ $file == 99-* ]]
    then
      say -y "Leaving '$file'"
    else
      (( ++ii ))
      if [[ $file =~ ^[0-9]{2}-(.+) ]]; then
        printf -v new_file '%02d-%s' "$ii" "${BASH_REMATCH[1]}"
        if [[ $file == "$new_file" ]]; then
          say -y "Leaving '$file'"
        else
          say -y "Moving  '$file' -> '$new_file'"
          (
            $option_verbose && set -x
            git mv "$file" "$new_file"
          )
        fi
      fi
    fi
  done
)

bash_versions=(
  3.2
  4.0
  4.1
  4.2
  4.3
  4.4
  5.0
  5.1
  5.2
)

test:test-in-docker() (
  [[ " ${bash_versions[*]} " == *" $option_bash "* ]] ||
    error "--option_bash must be one of ${bash_versions[*]}"

  if [[ ! $* ]]; then
    set -- test
  fi

  if $option_verbose; then
    set -- -v "$@"
  fi
  if $option_quiet; then
    set -- -q "$@"
  fi

  docker_image=$(ini:get test.docker-image)

  set -x
  docker run --rm -it \
    -v "$BPAN_ROOT":/bpan \
    -v "$PWD":/host \
    -v "$SSH_AUTH_SOCK":"$SSH_AUTH_SOCK" \
    -v "$HOME/.ssh/known_hosts":/root/.ssh/known_hosts \
    -w /host \
    -e SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
    -e BPAN_TEST_BASH_VERSION="$option_bash" \
    "$docker_image" \
      /bpan/test/bin/test-in-docker "$@"
)
