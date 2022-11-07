#!/usr/bin/env bash

# This is a template Bash/BPAN bin script to get you started.

VERSION='0.0.0'

# Locating our project root directory is the first step to bootstrap.
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)

# Then we can use the bundled bootstrapping library 'bpan.bash'.
# We source this with a dummy arg '--', otherwise $@ will be the calling args.
# Use '--app' to get the 'app' variable set to our app's name.
source "$root/.bpan/lib/bpan.bash" --app

# The 'bpan:source' function is used to source bash files from `./bpan/lib/`.
# Files are added there with `bpan add --pkg=...`.

bpan:source bashplus --err --sys

bpan:source getopt "\
getopt_default=--help

$app [<options>] <cmd> [<cmd-opts...>] [<cmd-args>]

$app is your friend.

Options:
--
v,verbose     Print more output
q,quiet       Print less output
#
h,help        Show the command summary
V,version     Display $app version
x,debug       Print lots of debugging info
"

# source "$root/lib/(% name %).bash"

main() (
  getopt "$@"
  set -- "${args[@]}"

  # (% name %):main "$@"

  echo "Hello, ${1-world}!"
)

main "$@"
