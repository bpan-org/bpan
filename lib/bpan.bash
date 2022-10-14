# This is the BPAN Bash bootstrap library.
# It sets up a sane Bash program runtime environment with minimal code.

# 'die' is so common we define a very basic one here.
# The 'bashplus' library defines a more full featured one.
die() { printf '%s\n' "$@" >&2; exit 1; }

# Assert that Bash in version 3.2 or higher:
( shopt -s compat31 2>/dev/null ) ||
  die "bpan.bash requires bash version 3.2 or higher"

# Put startup code in a function:
bpan:main() {
  # Settings to make Bash as strict as possible:
  {
    set -o errexit
    set -o nounset
    set -o pipefail
    shopt -s inherit_errexit
  } 2>/dev/null || true

  # 'source bpan.bash ...' can take arguments:
  local arg
  for arg do
    case "$arg" in
      # No arguments intended.
      # This is needed to ignore global '$@'.
      --) break;;

      # Set the 'app', 'App', and 'APP' variables:
      --app)
        app=$(basename "$0")
        if ( shopt -s compat31 2>/dev/null ); then  # bash 4.0+
          App=${app^}
          APP=${app^^}
        else
          App=$(tr '[:lower:]' '[:upper:]' <<<"${app:0:1}")${app:1}
          APP=$(tr '[:lower:]' '[:upper:]' <<<"$app")
        fi
        ;;

      *) die "Unknown argument '$arg' for '${BASH_SOURCE[0]}'";;
    esac
  done
}

# Try to source a bash library from one of:
# * A directory in BPAN_PATH
# * Local .bpan/lib/
# * BPAN_INSTALL/lib/
# * BPAN_ROOT/local/lib/
bpan:source() {
  [[ $# -gt 0 ]] ||
    die "Usage: bpan:source <bpan-library-name> [<arg>...]"
  local name=$1; shift
  local dir

  # shellcheck disable=2086
  for dir in $(IFS=:; echo ${BPAN_PATH-}); do
    if [[ -f $dir/$name.bash ]]; then
      source "$dir/$name.bash" "$@"
      return
    fi
  done

  dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
  dir=${dir#.bpan/}
  if [[ -f $dir/.bpan/lib/$name.bash ]]; then
    source "$dir/.bpan/lib/$name.bash" "$@"
    return
  fi

  if [[ ${BPAN_INSTALL-} ]] &&
     [[ -d ${BPAN_INSTALL}/lib/$name.bash ]]; then
    source "$dir/.bpan/lib/$name.bash" "$@"
  elif [[ ${BPAN_ROOT-} ]] &&
       [[ -d ${BPAN_ROOT}/local/lib/$name.bash ]]; then
    source "${BPAN_ROOT}/local/lib/$name.bash" "$@"
  fi
}

bpan:main "$@"
