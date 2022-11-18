#!/usr/bin/env bash

source test/init

install-test-bpan

try "set +eu; source '$root/.rc'"
is "$got" "" \
  "'source .rc' is quiet"

ok-d "$root"

is "$BPAN_ROOT" \
   "$root" \
   "BPAN_ROOT == '$root'"

ok-s "$root/config"

is "$(bpan config --global host.github.token)" \
   '___' \
   "BPAN global config has 'host.github.token = ___'"

done-testing
