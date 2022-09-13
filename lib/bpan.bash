#!/bash

bpan:main() {
  # Require Bash 3.2+
  bpan:bash32+ ||
    die "Bash 3.2 or higher is required"

  # Settings to make Bash as strict as possible:
  {
    set -e
    set -u
    set -o pipefail
    shopt -s inherit_errexit
  } 2>/dev/null || true

  local root
  root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
  [[ ${BPAN_ROOT-} && $root == "$BPAN_ROOT" ]] ||
    root=${root%/.bpan}

  export PATH=$root/.bpan/lib:$root/.bpan/bin:$PATH

  local arg
  for arg; do
    case "$arg" in
      --) :;;

      --app)
        app=$(basename "$0")
        if bpan:bash40+; then
          App=${app^}
          APP=${app^^}
        else
          App=$app
          APP=$app
        fi
        ;;

      --prelude) bpan:source prelude;;

      *) die "Unknown argument '$arg' for '${BASH_SOURCE[0]}'";;
    esac
  done
}

bpan:bash32+() ( shopt -s compat31 2>/dev/null )
bpan:bash40+() ( shopt -s compat32 2>/dev/null )
bpan:bash41+() ( shopt -s compat40 2>/dev/null )
bpan:bash42+() ( shopt -s compat41 2>/dev/null )
bpan:bash43+() ( shopt -s compat42 2>/dev/null )
bpan:bash44+() ( shopt -s compat43 2>/dev/null )
bpan:bash50+() ( shopt -s compat44 2>/dev/null )

bpan:source() {
  local name=$1; shift
  source "${BPAN_ROOT?}/.bpan/lib/$name.bash" "$@"
}

bpan:use() {
  local name=$1; shift
  source "$name.bash" "$@"
}

# Move to prelude
bpan:require-commands() (
  while read -r line; do
    [[ $line ]] || break
    command=${line#require.commands.}
    version=${command#*=}
    version=${version%+}
    command=${command%%=*}
    require-command-version "$command" "$version"
  done < <(
    git config -lf- <<<"$config" |
      grep "^require\.command\."
  )
)

# Global functions

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
