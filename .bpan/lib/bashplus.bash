# bashplus -- A collection of useful and portable functions:
#
# * All function names start with `+` so easy to recognize they are bashplus.
# * Many are improved versions of existing builtins/commands.


bashplus:version() ( echo '0.1.44' )

bashplus:main() {
  bashplus_lib=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

  bashplus_path=("$bashplus_lib")
  if [[ ${BPAN_INSTALL-} ]]; then
    bashplus_path+=("$BPAN_INSTALL/lib" "$BPAN_INSTALL/src")
  elif [[ $BPAN_ROOT ]]; then
    bashplus_path+=("$BPAN_ROOT/local/lib" "$BPAN_ROOT/local/src")
  fi

  local arg
  for arg; do
    if [[ $arg =~ ^--([a-z]+)$ ]]; then
      +source bashplus/"${arg#--}"

    elif [[ $arg =~ ^--bash=([345])\.([0-4])\+?$ ]]; then
      local n1=${BASH_REMATCH[1]} n2=${BASH_REMATCH[2]}
      +source bashplus/sys
      "+sys:bash$n1$n2" ||
        error "Requires Bash version $n1.$n2 or higher"

    elif [[ $arg == -- ]]; then
      break

    else
      warn "Warning: Invalid argument '$arg' for 'source bashplus'"
    fi
  done
}

# Source a name like 'foo' or 'foo/bar':
# shellcheck disable=2086
+source() {
  set +x
  local lib=${1?}; shift

  local path
  for path in "${bashplus_path[@]}" $(IFS=:; echo ${BASHPLUS_PATH-}); do
    if [[ -f $path/$lib.bash ]]; then
      source "$path/$lib.bash" "$@"
      return
    fi
  done

  die "Unable to '+source $lib'"
}

# A simple 'die' function. Full featured version is in lib/bashplus/err.bash
die() {
  set +x
  [[ $# -gt 0 ]] || set -- Died
  printf '%s\n' "$@" >&2
  exit 1
}

# A simple 'error' function. Full featured version is in lib/bashplus/err.bash
error() {
  set +x
  local msg="Error: ${1:-unknown}"; shift
  die "$msg" "$@"
}

# Print lines to stderr
warn() (
  set +x
  printf '%s\n' "$@" >&2
)

# Check if name is a callable function or command.
+can() {
  [[ $(command -v "${1:?+can requires a name argument}") ]] ||
    [[ $(type -t "$1") =~ ^(function|builtin)$ ]]
}

bashplus:main "$@"
