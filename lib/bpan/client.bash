#!/usr/bin/env bash

set -e

OPTIONS_SPEC="\
bpan <command> [<options>] [<arguments>]

Commands:
  find
  install

Options:
--
h           Show the command summary
 
t,tag=      Tag to use
q,quiet     Be more quiet
 
x           Debug - Turn on Bash trace (set -x) output
"

main() {
  get-opts "$@"

  "$command" "${command_arguments[@]}"
}

get-opts() {
  [ $# -eq 0 ] && set -- --help

  eval "$(
    echo "$OPTIONS_SPEC" |
      git rev-parse --parseopt -- "$@" ||
    echo exit $?
  )"

  tags=()
  quiet_mode=false

  while [ $# -gt 0 ]; do
    local option="$1"; shift
    case "$option" in
      -t) tag+=($1); shift ;;
      -g) quiet_mode=true ;;
      -x) set -x ;;
      --) break ;;
      *) die "Unexpected option: $option" ;;
    esac
  done

  command="$1"
  shift
  command_arguments=("$@")
}

[ "${BASH_SOURCE[0]}" == "$0" ] && main "$@"

true

# vim: set lisp:
