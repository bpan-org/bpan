#!/bash

( shopt -s compat31 2>/dev/null ) ||
  { echo "bpan.bash requires bash version 3.2 or higher">&2; exit 1; }

bpan:main() {
  # Settings to make Bash as strict as possible:
  {
    set -o errexit
    set -o nounset
    set -o pipefail
    shopt -s inherit_errexit
  } 2>/dev/null || true

  # Determine the app project/install's root directory:
  local root
  root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
  # Account for .bpan/ dir in project directories:
  [[ ${BPAN_ROOT-} && $root == "$BPAN_ROOT" ]] ||
    root=${root%/.bpan}

  # Add the app's BPAN dependency dir to PATH:
  export PATH=$root/.bpan/lib:$PATH

  # 'source bpan.bash ...' can take arguments:
  local arg
  for arg; do
    case "$arg" in
      # No arguments intended. Needed to ignore global '$@':
      --) break;;

      # Export the 'app', 'App', and 'APP' variables:
      --app)
        app=$(basename "$0")
        if ( shopt -s compat31 2>/dev/null ); then  # bash 4.0+
          App=${app^}
          APP=${app^^}
        else
          App=$app
          APP=$app
        fi
        ;;

      *) die "Unknown argument '$arg' for '${BASH_SOURCE[0]}'";;
    esac
  done
}

# This sources libraries from installed BPAN's .bpan/lib/ dir:
bpan:source() {
  local name=$1; shift
  source "${BPAN_ROOT?}/.bpan/lib/$name.bash" "$@"
}

# Global functions
#
# The following functions are used constantly in most Bash programs (including
# this file) so we declare them up front:

die() {
  local level=0
  local args=()
  local arg msg

  for arg; do
    if [[ $arg =~ ^--level=([0-9]+)$ ]]; then
      level=${BASH_REMATCH[1]}
    else
      args+=("$arg")
    fi
  done
  set -- "${args[@]}"

  if [[ $# -eq 0 ]]; then
    set -- Died
  elif [[ $# -eq 1 ]]; then
    msg=$1
    set -- "${msg//\\n/$'\n'}"
  fi

  printf "%s\n" "$@" >&2

  if [[ $# -eq 1 && $1 == *$'\n' ]]; then
    exit 1
  fi

  local c
  IFS=' ' read -r -a c <<< "$(caller "$level")"
  if (( ${#c[@]} == 2 )); then
    printf ' at line %d of %s\n' "${c[@]}" >&2
  else
    printf ' at line %d in %s of %s\n' "${c[@]}" >&2
  fi

  exit 1
}

warn() (
  [[ $# -gt 0 ]] ||
    set -- Warning
  printf '%s\n' "$@" >&2
)

bpan:main "$@"
