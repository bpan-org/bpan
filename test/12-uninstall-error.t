#!/usr/bin/env bash

source test/init

test-errors <<'...'
> bpan uninstall github:bpan-org/getopt-bash=9.9.9
[bpan] Error: No package 'github:bpan-org/getopt-bash=9.9.9' found
...

done-testing
