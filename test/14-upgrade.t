#!/usr/bin/env bash

source test/init

install-test-bpan

bpan -q upgrade

pass "'bpan upgrade' worked"

done-testing
