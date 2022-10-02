#!/usr/bin/env bash

source test/init

B=test/bin-pkg-bash
L=test/lib-pkg

rm -fr "$B"
rm -fr "$L"

if ! +is-cmd pandoc; then
  export PATH=$PWD/test/fake-bin:$PATH
fi

quiet=()
quiet=(--quiet)

#------------------------------------------------------------------------------
note "mkdir '$B'"
note "cd '$B' && bpan --quiet init --bin --config=Meta"
(
  mkdir -p "$B"
  cd "$B" || exit
  bpan "${quiet[@]}" init --bin --config=Meta
)

ok-d "$B/.git"
ok-f "$B/Meta"
ok-f "$B/.bpan/config"
ok-h "$B/.bpan/config"
ok-f "$B/.bpan/lib/bpan.bash"
ok-f "$B/.bpan/lib/bashplus.bash"
ok-f "$B/.bpan/lib/getopt.bash"
ok-f "$B/bin/bin-pkg"
ok-f "$B/.rc"
has "$(< "$B/.rc")" BIN_PKG_ROOT \
  "'$B/.rc' contains string 'BIN_PKG_ROOT'"
ok-not-e "$B/lib/bin-pkg.bash"
ok-f "$B/doc/bin-pkg.md"
ok-f "$B/man/man1/bin-pkg.1"
ok-f "$B/test/init"
ok-f "$B/test/00-shellcheck.t"
ok-not-e "$B/test/XX-template.t"
ok-f "$B/ReadMe.md"
ok-f "$B/Changes"
ok-f "$B/License"

has "$(head -20 "$B/.rc")" \
  BIN_PKG_ROOT \
  "'$B/.rc has 'BIN_PKG_ROOT'"

is "$(cd "$B" && bpan config require.package.bashplus)" \
  '0.0.0+' \
  "'[require.package]' has 'bashplus = 0.0.0+'"
is "$(cd "$B" && bpan config require.package.getopt-bash)" \
  '0.0.0+' \
  "'[require.package]' has 'getopt-bash = 0.0.0+'"

#------------------------------------------------------------------------------
note "mkdir '$L'"
note "cd '$L' && bpan --quiet init --lib"
(
  mkdir -p "$L"
  cd "$L" || exit
  bpan "${quiet[@]}" init --lib
)

ok-f "$L/.bpan/config"
ok-not-e "$L/Meta"
ok-not-e "$L/bin/lib-pkg"
ok-not-e "$L/.rc"
ok-f "$L/lib/lib-pkg.bash"
ok-f "$L/doc/lib-pkg.md"
ok-f "$L/test/init"
ok-f "$L/test/00-shellcheck.t"
ok-f "$L/ReadMe.md"
ok-f "$L/man/man3/lib-pkg.3"

#------------------------------------------------------------------------------
note "cd '$L' && bpan --quiet init --bin"
(
  cd "$L" || exit
  # bpan --quiet init --bin
  bpan "${quiet[@]}" init --bin
)

ok-f "$L/bin/lib-pkg"
ok-e "$L/.rc"
ok-f "$L/man/man1/lib-pkg.1"

#------------------------------------------------------------------------------
done-testing
