#!/usr/bin/env bash

set -e

use JSON

BPAN:VERSION() { grep -E 'version:' Meta | cut -d ' ' -f2; }

OPTIONS_SPEC="\
bpan <command> [<options>] [<arguments>]

Commands:
  find      Find BPAN packages
  install   Install a BPAN package
  update    Update the BPAN indexes
  upgrade   Upgrade 'bpan' (BPAN client)
  env       Get value of BPAN_XXX variable
  version   Show 'bpan' version

Dev Commands:
  makefile  Generate a Makefile for your BPAN Package
  register  Register your BPAN package with bpan.org

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
    if [ $(uname) == Darwin ]; then
      local prev=$(stat -f "%m" $index_stamp)
    else
      local prev=$(date --utc --reference=$index_stamp +%s)
    fi
    local now=$(date "+%s")
    local time=$(( now - prev ))
    # if [[ $(( now - prev )) -lt $(( 2 * 60 )) ]]; then
    if [[ $(( now - prev )) -lt $(( 60 * 60 * 24 )) ]]; then
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
  search_term="$1"
  check-index-up-to-date
  cat $package_index | JSON.load | sort |
  (
    count=0 name= owner= prev_name= prev_owner= short=false
    while read -r line; do
      [[ "$line" =~ ^/([^/$'\t']+)(/([^/$'\t']+))? ]] || die
      name="${BASH_REMATCH[1]}"
      if [ -z "$owner" ]; then
        owner="${BASH_REMATCH[3]}"
      fi
      [ -z "$prev_name" ] && prev_name="$name"
      [ -z "$prev_owner" ] && prev_owner="$owner"

      [ "$name" != "$prev_name" -o "$owner" != "$prev_owner" ] && found-entry

      if [[ "$line" =~ ^/([^/]+)/([^/]+)/([\.0-9]+)/([^$'\t']+)$'\t'\"(.*)\"$ ]]; then
        var="${BASH_REMATCH[4]}"
        var=${var//\//_}
        var=${var//=/__}
        value="${BASH_REMATCH[5]}"
        printf -v $var "$value"
      elif [[ "$line" =~ ^/([^/]+)/([^/]+)/([\.0-9]+)/([^$'\t']+)$'\t'(.*)$ ]]; then
        var="${BASH_REMATCH[4]}"
        var=${var//\//_}
        var=${var//=/__}
        value="${BASH_REMATCH[5]}"
        printf -v $var "$value"
      elif [[ "$line" =~ ^/([^/]+)$'\t'\"(.*)\"$ ]]; then
        short=true
      else
        : echo ">>$line"
      fi
    done
    found-entry
    if [ $count -eq 0 ]; then
      say "No packages found"
    fi
  )
}

found-entry() {
  if [ -n "$search_term" ]; then
    [[ "$prev_name" =~ $search_term ]] ||
    [[ "$abstract" =~ $search_term ]] ||
      return 0
  fi

  date="$(date -d @$release_timestamp +%F)"

  : $((count++))
  if $short; then
    echo "$count) $prev_name ($prev_owner/$prev_name) $version - $date"
  else
    echo "$count) $prev_name/$prev_owner $version - $date"
  fi
  if [ -n "$abstract" ]; then
    echo "   abstract: $abstract"
  fi
  if [ -n "$release_sha" ]; then
    echo "   sha1: $release_sha"
  fi
  echo "   url: ${release_url%.git}/tree/$version"
  prev_name="$name" prev_owner="$owner" name= owner= version= sha=
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

  local full_name="$(JSON.get -a /$name -)"
  local version="$(JSON.get -a /$full_name/0 -)"

  local url="$(JSON.get -a /$full_name/$version/release/url -)"
  [ -n "$url" ] || fail "Package '$name' not found"
  local sha="$(JSON.get -a /$full_name/$version/release/sha -)"
  [ -n "$sha" ] || fail "Package2 '$name' not found"
  local cmd="$(JSON.get -a /$full_name/$version/install/cmd -)"
  cmd="${cmd:-make install}"

  do-install
}

command:update() {
  do-update
  say "$BPAN_INDEX updated"
}

command:upgrade() {
  (
    say "> cd $BPAN_ROOT"
    cd $BPAN_ROOT

    local branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$branch" != master ]; then
      say "> git checkout master"
      git checkout master
    fi
    say "> git pull --rebase origin master"
    git pull --rebase origin master

    old_version="$(BPAN:VERSION)"
    source "$BPAN_ROOT/lib/bpan.bash"
    new_version="$(BPAN:VERSION)"
    say "BPAN client ('bpan') upgraded from '$old_version' to '$new_version'."
  )
}

command:env() {
  local var="${1:?variable name required}"
  echo "${!var}"
}

command:version() {
  echo "BPAN — version $(BPAN:VERSION)"
}

command:makefile() {
  bpan-makefile
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
