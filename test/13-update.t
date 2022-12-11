#!/usr/bin/env bash

source test/init

+source bashplus/git

install-test-bpan

bpan -q update --self

pass "'bpan update --self' worked"

done-testing
