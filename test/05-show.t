#!/usr/bin/env bash

source test/init

like "$(bpan show --cmds)" \
   "1) find *- Search for BPAN packages" \
   "'bpan cmds' works"

like "$(bpan show --cmds -q | xargs)" \
   "find .*install .*config .*init" \
   "'bpan cmds -q' works"

like "$(bpan --quiet show --cmds | xargs)" \
   "find .*install .*config .*init" \
   "'bpan --quiet cmds' works"

ok "$([[ $(bpan show --cmds | wc -l) -eq 10 ]])" \
   "'bpan cmds' has more than 10 entries"

done-testing
