#!/usr/bin/env bash

source test/init

+is-online ||
  skip-all "These tests need to be run online"

{
  test-install-setup
  command='bpan -q install getopt-bash'
  ok "$($command)" \
    "'$command' works"
  ok-d "$I/src/bpan-org/getopt-bash/"
  ok-l "$I/lib/getopt.bash"
  ok-f "$I/lib/getopt.bash"
  ok-l "$I/man/man3/getopt.3"
  ok-f "$I/man/man3/getopt.3"
}

{
  test-install-setup
  command='bpan -q install github:bpan-org/getopt-bash=0.1.0'
  ok "$($command)" \
    "'$command' works"
  ok-d "$I/src/bpan-org/getopt-bash/0.1.0/"
  ok-l "$I/lib/getopt.bash"
  ok-f "$I/lib/getopt.bash"
  ok-l "$I/man/man3/getopt.3"
  ok-f "$I/man/man3/getopt.3"

  note "Testing 'bpan uninstall' here since we have something to uninstall"

  command=${command/install/uninstall}
  ok "$($command)" \
    "'$command' works"
  ok-not-e "$I/src/bpan-org/getopt-bash/0.1.0/"
  ok-not-e "$I/lib/getopt.bash"
  ok-not-e "$I/man/man3/getopt.3"

  is "$(cd "$BPAN_INSTALL" && find . -mindepth 1)" \
    "./index.ini" \
    "Install directory is empty"
}

done-testing
