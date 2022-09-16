#!/usr/bin/env bash

source test/init

like "$(bpan cmds)" \
   "1) search     - Search for BPAN packages" \
   "'bpan cmds' works"

like "$(bpan cmds -q | xargs)" \
   "search install.*uninstall.*list.*config" \
   "'bpan cmds -q' works"

like "$(bpan --quiet cmds | xargs)" \
   "search install.*uninstall.*list.*config" \
   "'bpan --quiet cmds' works"

ok "$([[ $(bpan cmds | wc -l) -gt 15 ]])" \
   "'bpan cmds' has more than 15 entries"

done-testing
