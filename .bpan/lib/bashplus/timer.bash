if [[ ${EPOCHREALTIME-} != "${EPOCHREALTIME-}" ]]; then
  _bashplus_timer=${EPOCHREALTIME/./}

  +timer() {
    echo "$(( ${EPOCHREALTIME/./} - _bashplus_timer ))"
  }

  +timer:printf() {
    local format=${1?}; shift
    local time=$(( ${EPOCHREALTIME/./} - _bashplus_timer ))
    local seconds=$((time / 1000000))
    local string
    string=$(printf "%.6d" "$time")
    local microseconds=${string: -6}
    # shellcheck disable=2059
    printf "$format\n" "$seconds.$microseconds" >&2
  }

  +timer:reset() { _bashplus_timer=${EPOCHREALTIME/./}; }

  +timer:wrap() {
    +can +func:wrap || +source bashplus/func
    for func; do
      label=${timer_label:-"$(printf '%-20s' "$func") -> %ss"}
      eval "
        +timer:wrapper() {
          +timer:reset
          ::FUNC-CALL::
          +timer:printf '$label'
        }
      "
      +func:wrap +timer:wrapper "$func"
    done
    unset -f +timer:wrapper
  }

else
  +timer()        { die "'+timer' only works for Bash 5.0+"; }
  +timer:printf() { die "'+timer:label' only works for Bash 5.0+"; }
  +timer:reset()  { die "'+timer:reset' only works for Bash 5.0+"; }
  +timer:wrap()   { die "'+timer:wrap' only works for Bash 5.0+"; }
fi
