#!/usr/bin/env bash

source test/init

+is-online ||
  skip-all "These tests need to be run online"

test-errors <<'...'
> bpan install foo
[bpan] Error: No package 'github:bpan-org/foo' found
> bpan install x+y
[bpan] Error: Invalid package id 'x+y'
> bpan install gitbub:foo
[bpan] Error: Invalid package domain 'gitbub'
> bpan install
[bpan] Error: 'bpan install' requires one or more packages
> bpan install getopt-bash=9.9.9
[bpan] Error: Can't find commit for pkg 'github:bpan-org/getopt-bash' version '9.9.9'
...

done-testing
