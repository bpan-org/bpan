#!/usr/bin/env bash

source test/init

make --no-print-directory clean

ok-not-e test/bin-pkg-bash/
ok-not-e test/bpan-*-setup/
ok-not-e test/bpan-*-update/
ok-not-e test/dir/
ok-not-e test/lib-pkg/
ok-not-e test/local/

done-testing
