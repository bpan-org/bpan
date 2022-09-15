#!/usr/bin/env bash

root=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd -P)
source "$root/.bpan/lib/bpan.bash" --
# bpan:source bashplus
# bpan:source getopt

source "$root/lib/(% bpan.name %).bash"

main() (
  # getopt "$@"
  # set -- "${args[@]}"

  (% pkg %):run "$@"
)

main "$@"
