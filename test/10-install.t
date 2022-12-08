#!/usr/bin/env bash

source test/init

test-install-setup() {
  export BPAN_INSTALL=$PWD//test/local
  rm -fr "$BPAN_INSTALL"
  mkdir -p "$BPAN_INSTALL"

  I=$BPAN_INSTALL

#   trap test-install-teardown exit
}

test-install-teardown() (
  rm -fr ./test/local
)

{
  test-install-setup
  command='bpan -q install getopt-bash'
  ok "$($command)" \
    "'$command' works"
  ok-d "$I/src/github/bpan-org/getopt-bash/"
  ok-h "$I/lib/getopt.bash"
  ok-f "$I/lib/getopt.bash"
  ok-h "$I/man/man3/getopt.3"
  ok-f "$I/man/man3/getopt.3"
}

{
  test-install-setup
  command='bpan -q install github:bpan-org/getopt-bash=0.1.21'
  ok "$($command)" \
    "'$command' works"
  ok-d "$I/src/github/bpan-org/getopt-bash/0.1.21/"
  ok-h "$I/lib/getopt.bash"
  ok-f "$I/lib/getopt.bash"
  ok-h "$I/man/man3/getopt.3"
  ok-f "$I/man/man3/getopt.3"

  note "Testing 'bpan install --uninstall' - we have something to uninstall"

  command=${command/install/install --uninstall}
  ok "$($command)" \
    "'$command' works"
  ok-not-e "$I/src/github/bpan-org/getopt-bash/0.1.18/"
  ok-not-e "$I/lib/getopt.bash"
  ok-not-e "$I/man/man3/getopt.3"

  is "$(
        cd "$BPAN_INSTALL" &&
          find . \
            -mindepth 1 \
            -type f \
            -not -path './src/github/*/*-index/*' \
            -not -path './src/github/*/getopt-bash/.git/*'
      )" \
    "" \
    "Install directory is empty"
}

done-testing
