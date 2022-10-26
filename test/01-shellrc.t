#!/usr/bin/env bash

source test/init

test() {
  shell=$1; shift
  bash_bin=$(dirname "$BASH")
  if +can "$shell"; then
    # shellcheck disable=2086
    is "$(
      env -i \
        HOME="$HOME" \
        TERM="$TERM" \
        PATH="$bash_bin":"$(dirname "$(command -v "$shell")")":/bin:/usr/bin:/sbin \
        $shell \
        "$@" \
        -c "$source ./.rc && bpan | head -n1"
    )" \
      'usage: bpan [<opt...>] <cmd> [<cmd-opt...>] [<cmd-arg...>]' \
      "bpan works for $shell"

  else
    note "The '$shell' shell is not installed. Skipping"
  fi
}

source=source

note "tcsh testing doesn't work yet"
test bash --norc
test zsh
test fish

source='.'
test yash

source="BPAN_ROOT=$PWD ."
test ash
test dash
+os-macos ||  # XXX
  test posh
test ksh
test mksh
test sh

note "mrsh testing doesn't work yet"
# source="BPAN_ROOT=$PWD; ."
# test mrsh

done-testing

# vim: ft=sh:
