#!/usr/bin/env bash

source test/init

B=test/bin-pkg-bash
L=test/lib-pkg

rm -fr "$B"
rm -fr "$L"

if ! +is-cmd pandocx; then
  export PATH=$PWD/test/fake-bin:$PATH
fi

note "bpan --quiet new --bin --meta $B"
bpan --quiet new --bin --meta "$B"

note "bpan --quiet new --lib $L"
bpan --quiet new --lib "$L"

ok-f "$B/.rc"
ok-f "$B/ReadMe.md"
ok-f "$B/bin/bin-pkg"
ok-f "$B/lib/bin-pkg.bash"
ok-f "$B/.bpan/config"
# TODO Implement 'ok-h'
# ok-h "$B/.bpan/config"
ok-f "$B/Meta"

has "$(head -20 "$B/.rc")" \
  BIN_PKG_ROOT \
  "'$B/.rc has 'BIN_PKG_ROOT'"


ok-not-e "$L/.rc"
ok-f "$L/ReadMe.md"
ok-not-e "$L/bin/lib-pkg"
ok-f "$L/lib/lib-pkg.bash"
ok-not-e "$L/Meta"

done-testing
