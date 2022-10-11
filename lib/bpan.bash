# This is the BPAN Bash bootstrap library.
# It sets up a sane Bash program runtime environment with minimal code.

# 'die' is so common we define a very basic one here.
# The 'bashplus' library defines a more full featured one.
die() {
  printf '%s\n' "$@" >&2
  exit 1
}

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
  for arg; do
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

  # Set the BPAN_INSTALL variable (unless already set):
  if [[ ${BPAN_INSTALL-} ]]; then
    [[ -d ${BPAN_INSTALL} ]] ||
      die "BPAN_INSTALL='$BPAN_INSTALL' is not a directory"
  else
    if [[ ${BPAN_ROOT-} && -f $BPAN_ROOT/lib/bpan.bash ]]; then
      BPAN_INSTALL=$BPAN_ROOT/local
      [[ -d $BPAN_INSTALL/lib ]] ||
        mkdir -p "$BPAN_INSTALL/lib"
    fi
  fi

  # BPAN_PATH is an array of directories for 'bpan:source' to find libraries:
  BPAN_PATH=()

  # Determine the package project/install's root directory:
  local project_root
  project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
  project_root=${project_root#.bpan/}

  # Add the project's BPAN dependency directory:
  if [[ -d $project_root/.bpan/lib ]]; then
    BPAN_PATH+=("$project_root/.bpan/lib")
  fi

  # Add BPAN's install directory:
  if [[ ${BPAN_INSTALL-} && -d ${BPAN_INSTALL}/lib ]]; then
    BPAN_PATH+=("$BPAN_INSTALL}/lib")
  fi
}

# source libraries found in BPAN_PATH array.
#
# TODO support calling forms:
# * bpan:source foo
# * bpan:source foo/bar
# * bpan:source foo/bar arg1 arg2
# * bpan:source foo/bar=1.2.3               # TODO
# * bpan:source foo/bar=1.2.3+              # TODO
# * bpan:source foo/bar=1.2.3+ arg1 arg2    # TODO
bpan:source() {
  [[ $# -gt 0 ]] ||
    die "Usage: bpan:source <bpan-library-name> [<arg>...]"
  local name=$1; shift
  local dir

  for dir in "${BPAN_PATH[@]}"; do
    if [[ -f $dir/$name.bash ]]; then
      source "$dir/$name.bash" "$@"
      return
    fi
  done
}

bpan:main "$@"
