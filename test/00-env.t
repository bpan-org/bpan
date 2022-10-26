#!/usr/bin/env bash

# shellcheck disable=2016

source test/init

o() {
  local cmd out msg
  cmd=$1
  out=$(
    (
      eval "$cmd" 2>&1 || true
    ) |
      perl -p0 \
      -e '
        if (/\n./) {
          s/^/  /gm;
          $_="\n$_";
        }
      '
  )
  msg=$(printf '%-30s -> %s' "$1" "$out")
  pass "$msg"
}

o 'date'
o 'echo $BPAN_ROOT'
o 'echo $BPAN_SHELL'
o 'bpan --version'
o 'which bash'
o 'bash --version | head -n1'
o 'which git'
o 'git --version'
o 'echo $BASH_VERSION'
o 'echo $OSTYPE'
o 'which md2man'
o 'md2man --version'

done-testing
