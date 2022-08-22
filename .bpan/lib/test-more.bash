# test/more.bash - Complete TAP test framework for Bash
#
# Copyright (c) 2013-2020. Ingy döt Net.

set -e -u -o pipefail

# shellcheck disable=2034
Test__More_VERSION=0.0.5

source prelude.bash

check-command-version bash 3.2 ||
  die "test-more-bash requires bash 3.2+"

test-more:init() { test-tap:init "$@"; }

plan() { test-tap:plan "$@"; }
pass() { test-tap:pass "$@"; }
fail() { test-tap:fail "$@"; }
diag() { test-tap:diag "$@"; }
note() { test-tap:note "$@"; }
done-testing() { test-tap:done-testing "$@"; }
BAIL-OUT() { test-tap:BAIL-OUT "$@"; }
BAIL-ON-FAIL() { test-tap:BAIL-ON-FAIL "$@"; }

is() {
  local got=$1 want=$2 label=${3-}
  if [[ $got == "$want" ]]; then
    test-tap:pass "$label"
  else
    test-tap:fail "$label" test-more:is-fail
  fi
}

test-more:is-fail() {
  local Test__Tap_CALL_STACK_LEVEL=
  Test__Tap_CALL_STACK_LEVEL=$(( Test__Tap_CALL_STACK_LEVEL + 1 ))
  if [[ $want =~ $'\n' ]]; then
    echo "$got" > /tmp/got-$$
    echo "$want" > /tmp/want-$$
    diff -u /tmp/{want,got}-$$ >&2 || true
    wc /tmp/{want,got}-$$ >&2
    rm -f /tmp/{got,want}-$$
  else
    test-tap:diag "\
    got: '$got'
  expected: '$want'"
  fi
}

isnt() {
  local Test__Tap_CALL_STACK_LEVEL=
  Test__Tap_CALL_STACK_LEVEL=$(( Test__Tap_CALL_STACK_LEVEL + 1 ))
  local got=$1 dontwant=$2 label=${3-}
  if [[ $got != "$dontwant" ]]; then
    test-tap:pass "$label"
  else
    test-tap:fail "$label" test-more:isnt-fail
  fi
}

test-more:isnt-fail() {
    test-tap:diag "\
      got: '$got'
   expected: anything else"
}

ok() {
  if (exit "${1:-$?}"); then
    test-tap:pass "${2-}"
  else
    test-tap:fail "${2-}"
  fi
}

like() {
  local got=$1 regex=$2 label=${3-}
  if [[ $got =~ $regex ]]; then
    test-tap:pass "$label"
  else
    test-tap:fail "$label" test-more:like-fail
  fi
}

test-more:like-fail() {
    test-tap:diag "Got: '$got'"
}

unlike() {
  local got=$1 regex=$2 label=${3-}
  if [[ ! $got =~ $regex ]]; then
    test-tap:pass "$label"
  else
    test-tap:fail "$label" test-more:unlike-fail
  fi
}

test-more:unlike-fail() {
    test-tap:diag "Got: '$got'"
}

cmp-array() {
    local arrayname="$1[@]"
    local expname="$2[@]"
    local label=${3-}

    local array=("${!arrayname}")
    local expected=("${!expname}")

    is "$(printf "%s\n" "${array[@]}")" \
      "$(printf "%s\n" "${expected[@]}")" \
      "$label"
}

test-tap:init() {
  [[ ${BASH_SOURCE[0]} ]] ||
    test-tap:die "Error: test-tap-bash must be run under Bash only"
  Test__Tap_plan=0
  Test__Tap_run=0
  Test__Tap_failed=0
  Test__Tap_pid=${BASHPID:-0}

  if [[ $# -gt 0 ]]; then
    [[ $# -eq 2 ]] ||
      test-tap:die 'Usage: test/tap.bash tests <number>'
    test-tap:plan "$@"
  fi

  trap test-tap:END EXIT
}

skip-all() {
  plan skip-all "$@"
}

test-tap:plan() {
  test-tap:_check-pid
  [[ $# -eq 2 ]] ||
    test-tap:die 'Usage: plan tests <number>'
  if [[ $1 = tests ]]; then
    [[ $2 =~ ^-?[0-9]+$ ]] ||
      test-tap:die 'Plan must be a number'
    [[ $2 -gt 0 ]] ||
      test-tap:die 'Plan must greater then 0'
    Test__Tap_plan=$2
    printf "1..%d\n" "$Test__Tap_plan"
  elif [[ $1 == skip-all ]]; then
    printf "1..0 # SKIP %s\n" "$2"
    exit 0
  else
    test-tap:die 'Usage: plan tests <number>'
  fi
}

test-tap:pass() {
  test-tap:_check-pid
  ((++Test__Tap_run))
  local label=${1-}
  if [[ $label ]]; then
    echo "ok $Test__Tap_run - $label"
  else
    echo "ok $Test__Tap_run"
  fi
}

Test__Tap_CALL_STACK_LEVEL=1
test-tap:fail() {
  test-tap:_check-pid
  ((++Test__Tap_run))
  IFS=' ' read -r -a c <<<"$(caller $Test__Tap_CALL_STACK_LEVEL)"
  local file=${c[2]-}
  local line=${c[0]-}
  local label=${1-} callback=${2-}
  if [[ $label ]]; then
    echo "not ok $Test__Tap_run - $label"
  else
    echo "not ok $Test__Tap_run"
  fi
  label=${label:+"'$label'\n#   at $file line $line."}
  label=${label:-"at $file line $line."}
  echo -e "#   Failed test $label" >&2

  [[ $callback ]] && $callback

  local rc=${TEST_TAP_BAIL_ON_FAIL:-0}
  [[ $rc -eq 0 ]] || exit "$rc"
}

test-tap:done-testing() {
  test-tap:_check-pid
  Test__Tap_plan=$Test__Tap_run
  echo 1.."${1:-$Test__Tap_run}"
}

test-tap:diag() {
  test-tap:_check-pid
  local msg=$*
  msg="# ${msg//$'\n'/$'\n'# }"
  echo "$msg" >&2
}

test-tap:note() {
  test-tap:_check-pid
  local msg=$*
  msg="# ${msg//$'\n'/$'\n'# }"
  echo "$msg"
}

test-tap:BAIL-OUT() {
  test-tap:_check-pid
  Test__Tap_bail_msg=$*
  : "${Test__Tap_bail_msg:=No reason given.}"
  exit 255
}

test-tap:BAIL-ON-FAIL() {
  test-tap:_check-pid
  TEST_TAP_BAIL_ON_FAIL=1
}

test-tap:END() {
  local rc=$?
  test-tap:_check-pid
  if [[ $rc -ne 0 ]]; then
    if [[ ${Test__Tap_bail_msg-} ]] ||
       [[ ${TEST_TAP_BAIL_ON_FAIL-} ]]; then
      local bail=${Test__Tap_bail_msg:-"Bailing out on status=$rc"}
      echo "Bail out!  $bail"
      exit $rc
    fi
  fi

  if [[ $Test__Tap_plan -eq 0 ]]; then
    if [[ $Test__Tap_run -gt 0 ]]; then
      echo "# Tests were run but no plan was declared." >&2
    fi
  else
    if [[ $Test__Tap_run -eq 0 ]]; then
      echo "# No tests run!" >&2
    elif [[ $Test__Tap_run -ne $Test__Tap_plan ]]; then
      local msg="# Looks like you planned $Test__Tap_plan tests but ran $Test__Tap_run."
      [[ $Test__Tap_plan -eq 1 ]] && msg=${msg/tests/test}
      echo "$msg" >&2
    fi
  fi
  local exit_code=0
  if [[ $Test__Tap_failed -gt 0 ]]; then
    exit_code=$Test__Tap_failed
    [[ $exit_code -gt 254 ]] && exit_code=254
    local msg="# Looks like you failed $Test__Tap_failed tests of $Test__Tap_run run."
    [[ $Test__Tap_failed -eq 1 ]] && msg=${msg/tests/test}
    echo "$msg" >&2
  fi
  exit $exit_code
}

test-tap:_check-pid() {
  if [[ ${BASHPID:-0} -ne ${Test__Tap_pid:-0} ]]; then
    test-tap:die "Error: Called test-tap method from a subprocess" 3
  fi
}

test-more:init
