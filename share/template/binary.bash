#!/usr/bin/env bash

root=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd -P)
source "$root/.bpan/lib/bpan.bash" --
# bpan:source bashplus

# bpan:source getopt "\
# getopt_default=--help
#
# $app [<options>] <cmd> [<cmd-opts...>] [<cmd-args>]
#
# $app is your friend.
#
# Options:
# --
# v,verbose     Print more output
# q,quiet       Print less output
#
# h,help        Show the command summary
# V,version     Display $app version
# x,debug       Print lots of debugging info
# "

source "$root/lib/(% name %).bash"

main() (
  # getopt "$@"
  # set -- "${args[@]}"

  (% name %):run "$@"
)

main "$@"
