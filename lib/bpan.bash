# This is the BPAN Bash bootstrap library.
# It sets up a sane Bash program runtime environment with minimal code.

# 'die' is so common we define a very basic one here.
# The 'bashplus' library defines a more full featured one.
die() {
  [[ $# -gt 0 ]] || set -- Died
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

  # Determine the package project/install's root directory:
  local root
  root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)

  # Add the app's BPAN dependency dir to PATH:
  export PATH=${root%/.bpan}/.bpan/lib:$PATH

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
}

# This sources libraries from the installed BPAN's .bpan/lib/ dir:
bpan:source() {
  local name=$1; shift
  source "${BPAN_ROOT?}/.bpan/lib/$name.bash" "$@"
}

bpan:main "$@"
