#!/usr/bin/env bash

source test/init

has "$(bpan find getopt)" \
   "github:bpan-org/getopt-bash" \
   "Got '%W' in search results"

try 'bpan find . | grep version'
is "$rc" 1 \
  "'bpan search' output doesn't have 'version'"

done-testing
