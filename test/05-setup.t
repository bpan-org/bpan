#!/usr/bin/env bash

source test/init

root=$(pwd -P)/test/bpan

rm -fr "$root"

git clone -q .git "$root"
find .bpan bin lib |
  cpio -dump "$root" &>/dev/null

try "set +eu; source '$root/.rc'"
is "$got" "" \
  "'source .rc' is quiet"

set +eu
source "$root/.rc" || die
set -eu

ok-d "$root"

is "$BPAN_ROOT" \
   "$root" \
   "BPAN_ROOT == '$root'"

ok-s "$root/config"

is "$(bpan config --global github.token)" \
   '___' \
   "BPAN global config has 'github.token = ___'"

done-testing
