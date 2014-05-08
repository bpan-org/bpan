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
  version   Show 'bpan' version

Dev Commands:
  release   Release the next version of a package to BPAN
  register  Register your BPAN package with bpan.org

Miscellaneous Commands:
  env       Get value of BPAN_XXX variable

Options:
--
h,help      Show the command summary
 
t,tag=      Tag to use
q,quiet     Be more quiet
v,verbose   Be more verbose
 
x           Debug - Turn on Bash trace (set -x) output
"

main() {
  get-opts "$@"

  setup

  if can "command:$command"; then
    "command:$command" "${command_arguments[@]}"
  else
    error "unknown bpan command '$command'"
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
  verbose_mode=false

  while [ $# -gt 0 ]; do
    local option="$1"; shift
    case "$option" in
      -t) tag+=($1); shift ;;
      -q) quiet_mode=true ;;
      -v) verbose_mode=true ;;
      -x) set -x ;;
      --) break ;;
      *) error "unexpected option '$option'" ;;
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
    rm -fr index gh-pages
    git fetch origin
    git read-tree --prefix=gh-pages origin/gh-pages
    git checkout -- gh-pages
    git rm -r --cache gh-pages &> /dev/null
    mv gh-pages/index .
    rm -fr gh-pages
  )
  touch $index_stamp
}

# XXX Show version list.
command:find() {
  search_term="$1"
  check-index-up-to-date
  cat $package_index | JSON.load | sort |
  (
    count=0 name= owner= prev_name= prev_owner= short=false
    while read -r line; do
      if [[ "$line" =~ ^/([^/]+)/([^/]+)$'\t'\"([\.0-9\ ]+)\"$ ]]; then
        name="${BASH_REMATCH[1]}"
        owner="${BASH_REMATCH[2]}"
        versions="${BASH_REMATCH[3]}"
        version="${versions% *}"
        if [ -z "$prev_name" ]; then
          prev_name="$name"
          prev_owner="$owner"
          prev_version="$version"
          prev_versions="$versions"
        fi
        if [ "$name" != "$prev_name" ] || [ "$owner" != "$prev_owner" ]; then
          found-entry
        fi
        abstract="$(JSON.load < "$BPAN_ROOT/index/package/$name/$owner,$version" | JSON.get -a /abstract)"
      elif [[ "$line" =~ ^/([^/]+)/([^/]+)/([\.0-9]+)$'\t'\"(.*)\"$ ]]; then
        local list=( ${BASH_REMATCH[4]} )
        sha1="${list[0]}"
        stamp="${list[1]}"
        host="${list[2]}"
        hostid="${list[3]}"
        repo="${list[4]}"
      elif [[ "$line" =~ ^/([^/]+)$'\t'\"(.*)\"$ ]]; then
        short=true
      else
        die "Error parsing package index: '$line'"
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
    if [[ ! "$prev_name" =~ $search_term ]] &&
       [[ ! "$abstract" =~ $search_term ]]; then
      prev_name="$name" prev_owner="$owner" prev_version="$version"
      abstract= versions=
      return 0
    fi
  fi

  date="$(date -d @$stamp +%F)"

  : $((count++))
  if $short; then
    echo "$count) $prev_name ($prev_owner/$prev_name) $prev_version - $date"
  else
    echo "$count) $prev_name/$prev_owner $prev_version - $date"
  fi

  if $verbose_mode; then
    if [ -n "$abstract" ]; then
      echo "   abstract: $abstract"
    fi
    if [ -n "$sha1" ]; then
      echo "   sha: $sha1"
    fi
    echo "   url: https://github.com/$hostid/$repo/#readme"
    echo "   src: git@github.com:$hostid/$repo"
    if [[ "$prev_versions" =~ [[:space:]] ]]; then
      echo "   versions: ${prev_versions// /, }"
    fi
    echo
  fi

  prev_name="$name" prev_owner="$owner" prev_version="$version"
  prev_versions="$versions" abstract=
}

command:install() {
  [ $# -ge 1 ] ||
    error "package name required"
  local name="$1"; shift
  [ $# -eq 0 ] ||
    error "unknown args '$@'"

  check-index-up-to-date

  JSON.load "$(< $package_index)"

  local package= owner=
  if [[ "$name" =~ ^(.+)/(.+)$ ]]; then
    owner="${BASH_REMATCH[1]}"
    package="${BASH_REMATCH[2]}"
  else
    package="$name"
  fi
  [[ "$package" =~ ^[a-zA-Z][-a-zA-Z0-9]+$ ]] ||
    error "Invalid package name '$package'"
  if [ -z "$owner" ]; then
    local package_owner="$(JSON.get -a /$package -)"
    owner="${package_owner#*/}"
    [ -n "$owner" ] ||
      error "Can't find package '$name'"
  fi
  local versions=( $(JSON.get -a /$package/$owner -) )
  [ -n "$versions" ] ||
    error "Can't find package versions for '$name'"
  local version="${versions[0]}"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    error "Invalid version '$version' for '$name'"

  local info=( $(JSON.get -a /$package/$owner/$version -) )
  [ "${#info[@]}" -eq 5 ] ||
    error "Bad data for '$name': '${info[@]}'"

  local hostid="${info[3]}"
  local repo="${info[4]}"

  check-index-up-to-date

  local json_file="$BPAN_ROOT/index/package/$package/$owner,$version"
  [ -f "$json_file" ] ||
    error "Can't find package meta file '$PWD/$json_file'"
  JSON.load "$(< $json_file)"
  local cmd="$(JSON.get -a /install/cmd -)"
  cmd="${cmd:-make install}"

  # XXX resolve deps and make install list

  local url="https://github.com/$hostid/$repo.git"

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
  local var="$1"
  if [ -z "$var" ]; then
    ( set -o posix ; set ) | grep '^BPAN_' | sort
    return
  fi
  if [[ ! "$var" =~ ^BPAN_ ]] || [ -z "${!var}" ]; then
    error "invalid env variable '$var'"
  fi
  echo "${!var}"
}

command:version() {
  echo "BPAN — version $(BPAN:VERSION)"
}

command:register() {
  bpan-register
}

command:release() {
  bpan-release
}

do-install() {
  local build_dir="$BPAN_ROOT/build/$package,$owner,$version"
  rm -fr "$build_dir"
  (
    set -x
    git clone "$url" "$build_dir"
    cd "$build_dir"
    $cmd
  ) || error "package '$name' failed to install"
  say "Package '$name' installed"
}

say() {
  echo "$@"
}

nay() {
  echo "$@" >&2
}

error() {
  nay "Error: $@"
  exit 1
}

# vim: set lisp:
