#!/usr/bin/env bash

source test/init

test-errors <<'...'
> bpan uninstall getopt-bash=9.9.9
'github:bpan-org/getopt-bash=9.9.9' is not installed
...

done-testing
