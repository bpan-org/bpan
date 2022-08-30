#!/usr/bin/env bash

source test/init

bpan:use prelude

test() {
  shell=$1
  if can "$shell"; then
    # shellcheck disable=2086
    is "$(
      env -i PATH=/bin:/usr/bin $shell \
        $opts -c "$source ./.rc && bpan | head -n1" \
        2>/dev/null
    )" \
      'usage: bpan [<options>] <cmd> [<cmd-opts...>] [<cmd-args>]' \
      "bpan works for $shell"

  else
    note "The '$shell' shell is not installed. Skipping"
  fi
}

opts=''
source=source

opts='--norc' \
  test bash
test zsh
test fish
note "tcsh testing doesn't work yet"

source="BPAN_ROOT=$PWD ."
test ash
test dash
test posh
test ksh

done-testing

# vim: ft=sh:
