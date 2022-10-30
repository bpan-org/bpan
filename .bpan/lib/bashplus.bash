# bashplus -- A collection of useful and portable functions:
#
# * All function names start with `+` so easy to recognize they are bashplus.
# * Many are improved versions of existing builtins/commands.


bashplus:version() ( echo '0.1.43' )

bashplus:main() {
  bashplus_lib=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

  local arg
  for arg; do
    if [[ $arg =~ ^--([a-z]+)$ ]]; then
      source "$bashplus_lib/bashplus/${BASH_REMATCH[1]}.bash" --

    elif [[ $arg =~ ^--bash=([345])\.([0-4])\+?$ ]]; then
      local n1=${BASH_REMATCH[1]} n2=${BASH_REMATCH[2]}
      source "$bashplus_lib/sys.bash"
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

  if [[ -f $bashplus_lib/$lib.bash ]]; then
    source "$bashplus_lib/$lib.bash" "$@"
    return
  fi

  local path
  while read -r path; do
    if [[ -f $path/$lib.bash ]]; then
      source "$path/$lib.bash" "$@"
      break
    fi
  done < <(IFS=':'; printf '%s\n' $PATH)
}

# A simple 'die' function. Full featured version is in lib/bashplus/err.bash
die() {
  set +x
  [[ $# -gt 0 ]] || set -- Died
  warn "$@"
  exit 1
}

# A simple 'error' function. Full featured version is in lib/bashplus/err.bash
error() {
  set +x
  local msg="Error: $1"; shift
  die "$msg" "$@"
}

# Print lines to stderr
warn() {
  set +x
  printf '%s\n' "$@" >&2
}

# Check if name is a callable function or command.
+can() {
  [[ $(command -v "${1:?+can requires a name argument}") ]] ||
    [[ $(type -t "$1") =~ ^(function|builtin)$ ]]
}

bashplus:main "$@"
