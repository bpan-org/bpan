#!/usr/bin/env bash

source test/init

online ||
  skip-all "These tests need to be run online"

test-errors <<'...'
> bpan install foo
Error: No package 'github:bpan-org/foo' found
> bpan install x+y
Error: Invalid package id 'x+y'
> bpan install gitbub:foo
Error: Invalid package domain 'gitbub'
> bpan install
Error: 'bpan install' requires one or more packages
> bpan install prelude-bash=9.9.9
Error: Can't find commit for pkg 'github:bpan-org/prelude-bash' version '9.9.9'
...

done-testing
