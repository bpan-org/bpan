#!/usr/bin/env bash

source test/init

has "$(bpan search getopt)" \
   "github:bpan-org/getopt-bash" \
   "Got '%W' in search results"

done-testing
