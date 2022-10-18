#!/usr/bin/env bash

source test/init

is "$(bpan config index.bpan.repo-url)" \
  https://github.com/bpan-org/bpan-index \
  "Can read a value from bpan system config"

try 'bpan config --list | wc -l'

ok "$( (( got > 10 )) )" \
  "'bpan config --list' was more than 10 entries"

done-testing
