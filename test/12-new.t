#!/usr/bin/env bash

source test/init

B=test/bin-pkg
L=test/lib-pkg

trap 'rm -fr $B $L' exit

bpan --quiet new --bin "$B"

ok-f "$B/.rc"
ok-f "$B/bin/bin-pkg"
ok-f "$B/lib/bin-pkg.bash"

bpan --quiet new --lib "$L"

ok-not-e "$L/.rc"
ok-not-e "$L/bin/lib-pkg"
ok-f "$L/lib/lib-pkg.bash"

done-testing
