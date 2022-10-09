#!/usr/bin/env bash

source test/init

export HELLO=world
export GOODBYE='yellow brick road'

output=$(
  "$BASH" <(cat<<'...'
source "$BPAN_ROOT/lib/bpan.bash" --env "$@"
set
...
  ) || true
)

has "$output" "BASH_VERSION=" \
  "BASH_VERSION can be seen in clean env"
hasnt "$output" "HELLO=" \
  "BASH_VERSION can NOT be seen in clean env"


output=$(
  "$BASH" <(cat<<'...'
source "$BPAN_ROOT/lib/bpan.bash" --env=^HELLO "$@"
set
...
  ) || true
)

has "$output" "HELLO=" \
  "HELLO can be seen in clean --env=^HELLO"
hasnt "$output" "GOODBYE=" \
  "GOODBYE can NOT be seen in clean env"


output=$(
  "$BASH" <(cat<<'...'
source "$BPAN_ROOT/lib/bpan.bash" --
set
...
  ) || true
)

has "$output" "BASH_VERSION=" \
  "BASH_VERSION can be seen in dirty env"
has "$output" "HELLO=" \
  "BASH_VERSION can  be seen in dirty env"


rm -f "$BPAN_ROOT"/.bpan/pid-*


done-testing
