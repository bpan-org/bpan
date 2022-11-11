# 'die' is the most commonly used function that is missing from Bash.
# This one tries to emulate Perl's `die` as much as possible.
# It also supports:
# * --level for stack trace level adjustment
# * --red for error messages (to tty) in color red
# * --stack for full stack trace
# * --line to show line numbers
# * --plain to not show line numbers
#
# NOTE: 'die', 'errpr' and 'warn' are the only bashplus functions not
# starting with a '+' character.

die() {
  set "${BASHPLUS_DEBUG_BASH_X:-+x}"
  local arg args=() level=1 R='' Z=''
  local line=false plain=false stack=false

  for arg; do
    if [[ $arg =~ ^--level=([0-9]+)$ ]]; then
      level=$(( level + BASH_REMATCH[1] ))
    elif [[ $arg =~ ^--(line|plain|stack)$ ]]; then
      printf -v "${BASH_REMATCH[1]}" true
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

  (
    if $stack || [[ ${BASHPLUS_DEBUG_STACK-} ]]; then
      +stack-trace $level
    elif $plain; then
      :
    elif $line || [[ ${!#} != *$'\n' ]]; then
      +stack-trace $level 1
    fi
  ) >&2

  exit 1
}

+stack-trace() (
  set "${BASHPLUS_DEBUG_BASH_X:-+x}"

  max=15
  if [[ ${BASHPLUS_DEBUG_STACK-} =~ ^[0-9]+$ ]] &&
    (( BASHPLUS_DEBUG_STACK > 1 ))
  then
    max=$BASHPLUS_DEBUG_STACK
  fi
  level=$1 lines=${2:-$max} count=1

  while IFS=' ' read -r -a caller <<< "$(caller "$level")"; do
    case ${#caller[*]} in
      2)
        printf ' at line %-3d of %s\n' "${caller[@]}"
        line=${caller[0]}
        file=${caller[1]}
        ;;
      3)
        printf ' at line %-3d in %-15s of %s\n' "${caller[@]}"
        line=${caller[0]}
        file=${caller[2]}
        ;;
      *) break ;;
    esac

    if (( lines > 1 )); then
      text=$(tail -n+"$line" "$file" | head -n1)
      text=${text#"${text%%[![:space:]]*}"}
      echo "    ${text:0:75}"
    fi

    : $(( level++ ))
    if (( count++ >= lines )); then
      echo ' ...'
      break
    fi
  done
)

# Red die with 'Error: ' prefix
error() {
  set "${BASHPLUS_DEBUG_BASH_X:-+x}"

  local msg

  if [[ ${app-} && $app =~ ^[-a-z0-9]+$ ]]; then
    msg="[$app] Error: $1"
  else
    msg="Error: $1"
  fi
  shift

  die --plain --red --level=1 "$msg" "$@"
}

# Allow multiple traps to be performed.
+trap() {
  set "${BASHPLUS_DEBUG_BASH_X:-+x}"
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
