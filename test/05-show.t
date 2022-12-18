#!/usr/bin/env bash

source test/init

like "$(bpan show --commands)" \
   "1) find *- Search for BPAN packages" \
   "'bpan show --commands' works"

like "$(bpan show --commands -q | xargs)" \
   "find .*install .*config .*init" \
   "'bpan show --commands -q' works"

like "$(bpan --quiet show --commands | xargs)" \
   "find .*install .*config .*init" \
   "'bpan --quiet show --commands' works"

ok "$([[ $(bpan show --commands | grep -c '[0-9])') -eq 10 ]])" \
   "'bpan show --commands' has 10 entries"

done-testing
