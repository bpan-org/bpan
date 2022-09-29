#!/usr/bin/env bash

source test/init

B=test/bin-pkg-bash
D=test/dir
L=test/lib-pkg
R=test/bpan

rm -fr "$B"
rm -fr "$D"
rm -fr "$L"
rm -fr "$R"

ok-not-e "$B"
ok-not-e "$D"
ok-not-e "$L"
ok-not-e "$R"

done-testing
