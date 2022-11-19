#!/usr/bin/env bash

source test/init

has "$(bpan search getopt)" \
   "github:bpan-org/getopt-bash" \
   "Got '%W' in search results"

try 'bpan search . | grep version'
is "$rc" 1 \
  "'bpan search' output doesn't have 'version'"

done-testing
