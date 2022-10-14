#!/usr/bin/env bash

source test/init

B=test/bin-pkg-bash
D=test/dir
L=test/lib-pkg
R=test/bpan
I=test/local

rm -fr "$B"
rm -fr "$D"
rm -fr "$L"
rm -fr "$R"
rm -fr "$I"

ok-not-e "$B"
ok-not-e "$D"
ok-not-e "$L"
ok-not-e "$R"
ok-not-e "$I"

done-testing
