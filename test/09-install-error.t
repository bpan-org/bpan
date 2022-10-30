#!/usr/bin/env bash

source test/init

+sys:online ||
  skip-all "These tests need to be run online"

test-errors <<'...'
> bpan install foo
[bpan] Error: No package 'github:bpan-org/foo' found
> bpan install x+y
[bpan] Error: Invalid package id 'x+y'
> bpan install gitbub:foo
[bpan] Error: Invalid package host 'gitbub'
> bpan install
usage: bpan [<bpan-opts>] install [<cmd-opts>] <pkg-id...>
> bpan install getopt-bash=9.9.9
[bpan] Error: Can't find commit for package 'github:bpan-org/getopt-bash' version '9.9.9'
...

done-testing
