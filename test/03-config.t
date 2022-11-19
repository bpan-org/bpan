#!/usr/bin/env bash

source test/init

ok "$([[ $(bpan config bpan.version) == 0.1.* ]])" \
  "Can read a value from bpan system config"

try 'bpan config --list | wc -l'

ok "$( (( got > 10 )) )" \
  "'bpan config --list' was more than 10 entries"

done-testing
