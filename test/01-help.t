#!/usr/bin/env bash

source test/init

# shellcheck disable=2153
version=$(git config -f "$BPAN_ROOT/Meta" bpan.version)

is "$(cd /tmp && bpan --version)" \
   "bpan $version" \
   "'bpan --version' works"

ok "$([[ $(bpan) == usage:\ bpan* ]])" \
   "'bpan' prints usage"

ok "$([[ $(bpan -h) == usage:\ bpan* ]])" \
   "'bpan -h' prints usage"

ok "$([[ $(bpan --help) == usage:\ bpan* ]])" \
   "'bpan --help' prints usage"

done-testing
