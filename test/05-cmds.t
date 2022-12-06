#!/usr/bin/env bash

source test/init

like "$(bpan cmds)" \
   "1) find *- Search for BPAN packages" \
   "'bpan cmds' works"

like "$(bpan cmds -q | xargs)" \
   "find .*install .*config .*init" \
   "'bpan cmds -q' works"

like "$(bpan --quiet cmds | xargs)" \
   "find .*install .*config .*init" \
   "'bpan --quiet cmds' works"

ok "$([[ $(bpan cmds | wc -l) -gt 10 ]])" \
   "'bpan cmds' has more than 10 entries"

done-testing
