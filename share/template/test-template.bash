#!/usr/bin/env bash

# A SAMPLE TEST FILE TO START NEW TESTS FROM

source test/init

try some --command

is "$got" 'expected string' \
  "Got '%W'"

ok-f "some/file"
ok-d "some/directory"
ok-h "some/symlink"
ok-not-e "not/a/file"

done-testing
