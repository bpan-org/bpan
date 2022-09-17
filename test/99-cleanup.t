#!/usr/bin/env bash

source test/init

B=test/bin-pkg-bash
L=test/lib-pkg
R=test/bpan

rm -fr "$B"
rm -fr "$L"
rm -fr "$R"

ok-not-e "$B"
ok-not-e "$L"
ok-not-e "$R"

done-testing
