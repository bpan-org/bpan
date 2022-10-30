# 'die' is the most commonly used function that is missing from Bash.
# This one tries to emulate Perl's `die` as much as possible.
# It also supports:
# * --level for stack trace level adjustment
# * --red for error messages (to tty) in color red
# * TODO --line to show line numbers
# * TODO --plain to not show line numbers
# * TODO --stack for full stack trace
#
# NOTE: 'die', 'errpr' and 'warn' are the only bashplus functions not
# starting with a '+' character.

die() {
  set +x
  local arg args=() level=0 R='' Z=''

  for arg; do
    if [[ $arg =~ ^--level=([0-9]+)$ ]]; then
      level=${BASH_REMATCH[1]}
    elif [[ $arg == --red ]]; then
      if [[ -t 2 ]]; then
        R='\e[31m'
        Z='\e[0m'
      fi
    else
      args+=("${arg//\\n/$'\n'}")
    fi
  done

  set -- "${args[@]}"
  [[ $# -gt 0 ]] || set -- Died

  (
    echo -en "$R"
    printf '%s\n' "$@"
    echo -en "$Z"
  ) >&2

  # If last msg line does not end with newline, then print line number:
  if [[ ${!#} != *$'\n' ]]; then
    local caller
    IFS=' ' read -r -a caller <<< "$(caller "$level")"
    if (( ${#caller[@]} == 2 )); then
      printf ' at line %d of %s\n' "${caller[@]}" >&2
    else
      printf ' at line %d in %s of %s\n' "${caller[@]}" >&2
    fi
  fi

  exit 1
}

# Red die with 'Error: ' prefix
error() {
  set +x
  local msg
  if [[ ${app-} && $app =~ ^[-a-z0-9]+$ ]]; then
    msg="[$app] Error: $1"
  else
    msg="Error: $1"
  fi
  shift
  die --red --level=1 "$msg" "$@"
}

# Allow multiple traps to be performed.
+trap() {
  set +x
  +can +sym || +source sym
  code=$1
  sig=${2:-exit}
  var=$(+sym trap)
  prev=$(trap -p "$sig" | cut -d"'" -f2)
  eval "$var() {
    $prev
    $1
  }"
  # shellcheck disable=2064
  trap "$var" "$sig"
}
