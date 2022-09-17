#!/usr/bin/env bash

source test/init

B=test/bin-pkg-bash
L=test/lib-pkg

rm -fr "$B"
rm -fr "$L"

ok-not-e "$B"
ok-not-e "$L"

done-testing
