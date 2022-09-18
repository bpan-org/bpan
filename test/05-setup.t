#!/usr/bin/env bash

source test/init

root=$(pwd -P)/test/bpan

rm -fr "$root"

git clone -q .git "$root"
cp lib/setup.bash "$root/lib/setup.bash"
cp lib/file.bash "$root/lib/file.bash"

set +eu
source "$root/.rc" || die
set -eu

ok-d "$root"

is "$BPAN_ROOT" \
   "$root" \
   "BPAN_ROOT == '$root'"

ok-f "$root/config"

is "$(bpan config bpan.user.token)" \
   '___' \
   "BPAN global config has 'bpan.user.token = ___'"

done-testing
