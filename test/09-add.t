#!/usr/bin/env bash

source test/init

quiet=()
quiet=(--quiet)

try bpan add --files

want=(
  .bpan/lib/bpan.bash
  lib/bpan.bash
  bin/bpan
  lib/bpan.bash
  test/init
  test/00-shellcheck.t
  test/XX-template.t
  doc/bpan.md
  Changes
  License
  Makefile
  .gitignore
  .rc
)

for file in "${want[@]}"; do
  has "$got" "$file" \
    "'bpan add --files' has '$file'"
done

D=test/dir

rm -fr "$D"
mkdir -p "$D"

(cd "$D" && bpan "${quiet[@]}" add --config)
ok-f "$D/.bpan/config"

(cd "$D" && bpan "${quiet[@]}" add --file=.rc --file=Changes)
ok-f "$D/.rc"
ok-f "$D/Changes"

(cd "$D" && bpan "${quiet[@]}" add --file=.gitignore)
ok-f "$D/.gitignore"

ok-not-e "$D/test/init"
(cd "$D" && bpan "${quiet[@]}" add --test)
ok-f "$D/test/init"
ok-f "$D/test/00-shellcheck.t"
ok-not-e "$D/test/XX-template.t"

(cd "$D" && bpan "${quiet[@]}" add --file=test/XX-template.t)
ok-f "$D/test/XX-template.t"

(cd "$D" &&
  bpan "${quiet[@]}" add \
    --pkg=github:bpan-org/bashplus \
    --pkg=github:bpan-org/getopt-bash
)
ok-f "$D/.bpan/lib/bashplus.bash"

done-testing
