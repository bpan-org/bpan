#!/usr/bin/env bash

source test/init

+source bashplus/git

install-test-bpan

branch=$(bpan config package.branch)

(
  cd "$BPAN_ROOT" || exit
  [[ $(+git:branch-name) == "$branch" ]] ||
    git checkout -q -b "$branch"
)

bpan -q update --self

pass "'bpan update --self' worked"

done-testing
