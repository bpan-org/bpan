#!/usr/bin/env bash

source test/init

root=$(pwd -P)/test/bpan

rm -fr "$root"

git clone -q .git "$root"
cp \
  lib/add.bash \
  lib/env.bash \
  lib/setup.bash \
  "$root"/lib/

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

try bpan setup --config
has "$got" \
  "Won't overwrite existing BPAN config file" \
  "'source .rc' is quiet"

try bpan setup --config --force
ok-s "$root/config"

done-testing
