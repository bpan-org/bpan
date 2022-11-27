#!/usr/bin/env bash

source test/init

test-errors <<'...'
> bpan install github:bpan-org/foo
[bpan] Error: No package 'github:bpan-org/foo' found
> bpan install x+y
[bpan] Error: Invalid package id 'x+y'
> bpan install gitbub:foo
[bpan] Error: No package 'gitbub:foo' found
> bpan install
usage: bpan [<bpan-opts>] install [<cmd-opts>] <pkg-id...>
> bpan install getopt-bash=9.9.9
[bpan] Error: No package 'getopt-bash=9.9.9' found
...

done-testing
