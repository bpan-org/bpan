#!/usr/bin/env bash

set -e

use JSON

BPAN::CLIENT:VERSION() { grep -E 'version:' Meta | cut -d ' ' -f2; }

OPTIONS_SPEC="\
bpan <command> [<options>] [<arguments>]

Commands:
  find      Find BPAN packages
  install   Install a BPAN package
  update    Update the BPAN indexes
  upgrade   Upgrade 'bpan' (BPAN client)
  env       Get value of BPAN_XXX variable
  version   Show 'bpan' version

Options:
--
h,help      Show the command summary
 
t,tag=      Tag to use
q,quiet     Be more quiet
 
x           Debug - Turn on Bash trace (set -x) output
"

main() {
  get-opts "$@"

  setup

  if can "command:$command"; then
    "command:$command" "${command_arguments[@]}"
  else
    fail "Unknown command '$command'"
  fi
}

get-opts() {
  [ $# -eq 0 ] && set -- --help

  eval "$(
    say "$OPTIONS_SPEC" |
      git rev-parse --parseopt -- "$@" ||
    say exit $?
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
      *) fail "Unexpected option: $option" ;;
    esac
  done

  command="$1"
  shift
  command_arguments=("$@")
}

setup() {
  author_index=$BPAN_INDEX/author.json
  package_index=$BPAN_INDEX/package.json
  index_stamp=$BPAN_INDEX/up-to-date
}

check-index-up-to-date() {
  if [ -f $index_stamp ]; then
    local prev=$(date --utc --reference=$index_stamp +%s)
    local now=$(date "+%s")
    local time=$(( now - prev ))
    if [[ $(( now - prev )) -lt $(( 2 * 60 )) ]]; then
    # if [[ $(( now - prev )) -lt $(( 60 * 60 * 24 )) ]]; then
      return
    fi
  fi
  do-update
}

do-update() {
  say "Updating $BPAN_INDEX"
  (
    cd $BPAN_ROOT
    # assert-git-clean
    git fetch origin
    git read-tree --prefix=index origin/gh-pages
    git checkout -- index
    git rm -r --cache index &> /dev/null
  )
  touch $index_stamp
}

command:find() {
  check-index-up-to-date
  cat $package_index | JSON.load
}

command:install() {
  [ $# -lt 1 ] &&
    fail "Package name required"
  local name="$1"
  shift
  [ $# -gt 0 ] &&
    fail "Unknown args '$@'"
  check-index-up-to-date

  JSON.load "$(< $package_index)"

  # XXX resolve deps and make install list

  local url="$(JSON.get -a /ingydotnet/$name/release/url -)"
  [ -n "$url" ] || fail "Package '$name' not found"
  local sha="$(JSON.get -a /ingydotnet/$name/release/sha -)"
  [ -n "$sha" ] || fail "Package '$name' not found"
  local cmd="$(JSON.get -a /ingydotnet/$name/install/cmd -)"
  cmd="${cmd:-make install}"

  do-install
}

command:update() {
  do-update
  say "$BPAN_INDEX updated"
}

command:upgrade() {
  (
    set -x
    cd $BPAN_ROOT
    git fetch
    git checkout client
    git rebase -p origin client
  )
  local old_version="$(BPAN::CLIENT:VERSION)"
  source "$BPAN_ROOT/lib/bpan/client.bash"
  local new_version="$(BPAN::CLIENT:VERSION)"
  say "BPAN client ('bpan') upgraded from '$old_version' to '$new_version'."
}

command:env() {
  local var="${1:?variable name required}"
  echo "${!var}"
}

command:version() {
  echo "BPAN — version $(BPAN::CLIENT:VERSION)"
}

do-install() {
  (
    rm -fr "$BPAN_BUILD/$repo"
    git clone "$url" "$BPAN_BUILD/$repo"
    cd "$BPAN_BUILD/$repo"
    $cmd
  ) || fail "Package '$name' failed to install"
  say "Package '$name' installed"
}

say() {
  echo "$@"
}

nay() {
  echo "$@" >&2
}

fail() {
  nay "Error: $@"
  exit 1
}

# vim: set lisp:
