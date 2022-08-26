# test-more.bash - Complete TAP test framework for Bash
#
# Copyright (c) 2013-2022. Ingy döt Net.

: "${BPAN_VERSION:?}"

bpan:use prelude

check-command-version bash 3.2 ||
  die "test-more-bash requires bash 3.2+"

test-more:main() {
  [[ ${BASH_SOURCE[0]} ]] ||
    die "Error: test-more-bash must be run under Bash only"
  _test_more__plan=0
  _test_more__run=0
  _test_more__failed=0
  _test_more__pid=${BASHPID:-0}

  if [[ $# -gt 0 ]]; then
    [[ $# -eq 2 ]] ||
      die 'Usage: source test-more.bash tests <number>'
    plan "$@"
  fi

  trap test-more:END EXIT
}

plan() {
  test-more:_check-pid
  if [[ $# -eq 2 && $1 == skip-all ]]; then
    printf "1..0 # SKIP %s\n" "$2"
    exit 0
  fi

  if [[ $# -eq 2 && $1 == tests ]]; then
    shift
  fi

  if [[ $# -eq 1 ]]; then
    [[ $1 =~ ^-?[0-9]+$ ]] ||
      die 'Plan must be a number'
    [[ $1 -gt 0 ]] ||
      die 'Plan must greater then 0'
    _test_more__plan=$1
    printf "1..%d\n" "$_test_more__plan"
  else
    die 'Usage: plan <number>'
  fi
}

pass() {
  test-more:_check-pid
  ((++_test_more__run))
  local label=${1-}
  if [[ $label ]]; then
    echo "ok $_test_more__run - $label"
  else
    echo "ok $_test_more__run"
  fi
}

_test_more__CALL_STACK_LEVEL=1
fail() {
  test-more:_check-pid
  ((++_test_more__run))
  IFS=' ' read -r -a c <<<"$(caller $_test_more__CALL_STACK_LEVEL)"
  local file=${c[2]-}
  local line=${c[0]-}
  local label=${1-} callback=${2-}
  if [[ $label ]]; then
    echo "not ok $_test_more__run - $label"
  else
    echo "not ok $_test_more__run"
  fi
  label=${label:+"'$label'\n#   at $file line $line."}
  label=${label:-"at $file line $line."}
  echo -e "#   Failed test $label" >&2

  [[ $callback ]] && $callback

  local rc=${TEST_MORE_BAIL_ON_FAIL:-0}
  [[ $rc -eq 0 ]] || exit "$rc"
}

is() {
  local got=$1 want=$2 label=${3-}
  if [[ $got == "$want" ]]; then
    pass "$label"
  else
    fail "$label" test-more:is-fail
  fi
}

test-more:is-fail() {
  local _test_more__CALL_STACK_LEVEL=
  _test_more__CALL_STACK_LEVEL=$(( _test_more__CALL_STACK_LEVEL + 1 ))
  if [[ $want =~ $'\n' ]]; then
    echo "$got" > /tmp/got-$$
    echo "$want" > /tmp/want-$$
    diff -u /tmp/{want,got}-$$ >&2 || true
    wc /tmp/{want,got}-$$ >&2
    rm -f /tmp/{got,want}-$$
  else
    diag "\
    got: '$got'
  expected: '$want'"
  fi
}

isnt() {
  local _test_more__CALL_STACK_LEVEL=
  _test_more__CALL_STACK_LEVEL=$(( _test_more__CALL_STACK_LEVEL + 1 ))
  local got=$1 dontwant=$2 label=${3-}
  if [[ $got != "$dontwant" ]]; then
    pass "$label"
  else
    fail "$label" test-more:isnt-fail
  fi
}

test-more:isnt-fail() {
    diag "\
      got: '$got'
   expected: anything else"
}

ok() {
  if (exit "${1:-$?}"); then
    pass "${2-}"
  else
    fail "${2-}"
  fi
}

like() {
  local got=$1 regex=$2 label=${3-}
  if [[ $got =~ $regex ]]; then
    pass "$label"
  else
    fail "$label" test-more:like-fail
  fi
}

test-more:like-fail() {
    diag "Got: '$got'"
}

unlike() {
  local got=$1 regex=$2 label=${3-}
  if [[ ! $got =~ $regex ]]; then
    pass "$label"
  else
    fail "$label" test-more:unlike-fail
  fi
}

test-more:unlike-fail() {
    diag "Got: '$got'"
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

skip-all() {
  plan skip-all "$@"
}

done-testing() {
  test-more:_check-pid
  _test_more__plan=$_test_more__run
  echo 1.."${1:-$_test_more__run}"
}

diag() {
  test-more:_check-pid
  local msg=$*
  msg="# ${msg//$'\n'/$'\n'\# }"
  echo "$msg" >&2
}

note() {
  test-more:_check-pid
  local msg=$*
  msg="# ${msg//$'\n'/$'\n'\# }"
  echo "$msg"
}

BAIL-OUT() {
  test-more:_check-pid
  _test_more__bail_msg=$*
  : "${_test_more__bail_msg:=No reason given.}"
  exit 255
}

BAIL-ON-FAIL() {
  test-more:_check-pid
  TEST_MORE_BAIL_ON_FAIL=1
}

test-more:END() {
  local rc=$?
  test-more:_check-pid
  if [[ $rc -ne 0 ]]; then
    if [[ ${_test_more__bail_msg-} ]] ||
       [[ ${TEST_MORE_BAIL_ON_FAIL-} ]]; then
      local bail=${_test_more__bail_msg:-"Bailing out on status=$rc"}
      echo "Bail out!  $bail"
      exit $rc
    fi
  fi

  if [[ $_test_more__plan -eq 0 ]]; then
    if [[ $_test_more__run -gt 0 ]]; then
      echo "# Tests were run but no plan was declared." >&2
    fi
  else
    if [[ $_test_more__run -eq 0 ]]; then
      echo "# No tests run!" >&2
    elif [[ $_test_more__run -ne $_test_more__plan ]]; then
      local msg="# Looks like you planned $_test_more__plan tests but ran $_test_more__run."
      [[ $_test_more__plan -eq 1 ]] && msg=${msg/tests/test}
      echo "$msg" >&2
    fi
  fi
  local exit_code=0
  if [[ $_test_more__failed -gt 0 ]]; then
    exit_code=$_test_more__failed
    [[ $exit_code -gt 254 ]] && exit_code=254
    local msg="# Looks like you failed $_test_more__failed tests of $_test_more__run run."
    [[ $_test_more__failed -eq 1 ]] && msg=${msg/tests/test}
    echo "$msg" >&2
  fi
  exit $exit_code
}

test-more:_check-pid() {
  if [[ ${BASHPID:-0} -ne ${_test_more__pid:-0} ]]; then
    die "Error: Called test-more method from a subprocess" 3
  fi
}

test-more:main "$@"
