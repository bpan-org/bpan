#!/usr/bin/env bash

source test/init

test-errors <<'...'
> bpan uninstall prelude-bash=9.9.9
'github:bpan-org/prelude-bash=9.9.9' is not installed
...

done-testing
