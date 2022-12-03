#!/usr/bin/env bash

source test/init

file=$(echo test/local/src/github/bpan-org/bashplus/*/lib/bashplus.bash)
if ! [[ -f $file ]]; then
  note "Installing 'github:bpan-org/bashplus'"
  bpan -q install bashplus
fi

has "$(bpan find --installed)" \
   "github:bpan-org/bashplus" \
   "Got '%W' in search results"

has "$(export BPAN_INSTALL=/; bpan find -i)" \
  "No BPAN packages currently installed" \
  "Got '%W' in search results"

done-testing
