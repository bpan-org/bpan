# bashplus -- A collection of useful and portable functions:
#
# * All function names start with `+` so easy to recognize they are bashplus.
# * Many are improved versions of existing builtins/commands.


bashplus:version() (
  VERSION=0.1.28
  echo "$VERSION"
)


# Define these first for use within:

  # 'die' is the most commonly used function that is missing from Bash.
  # This one tries to emulate Perl's `die` as much as possible.
  # It also supports:
  # * --level for stack trace level adjustment
  # * --red for error messages (to tty) in color red
  # * TODO --line to show line numbers
  # * TODO --plain to not show line numbers
  # * TODO --stack for full stack trace
  #
  # NOTE: 'die' and 'warn' are the only bashplus functions not starting with
  # a '+' character.

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

    echo -en "$R"
    printf '%s\n' "$@" >&2
    echo -en "$Z"

    if [[ $# -ne 1 || $1 != *$'\n' ]]; then
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

  warn() {
    printf '%s\n' "$@" >&2
  }

  # Check if name is a callable function or command.
  +can() {
    +is-func "${1:?+can requires a function name}" || +is-cmd "$1"
  }

  # Check if a name is a command.
  +is-cmd() [[ $(command -v "${1:?+is-cmd requires a command name}") ]]

  # Check if name is a function.
  +is-func() [[
    $(type -t "${1:?+is-func requires a function name}") == function ]]

  # OS type checks:
  +os-linux() [[ $OSTYPE == linux* ]]
  +os-macos() [[ $OSTYPE == darwin* ]]


# NOTE: BashPlus functions defined in name order.

# Functions to redirect stdout and stderr.
+1:x() { "$@" 1>/dev/null; }
+2:1() { "$@" 2>&1;        }
+2:x() { "$@" 2>/dev/null; }
+o:x() { "$@" &>/dev/null; }

# Functions to assert that commands are available.
+assert-cmd() ( +is-cmd "$@" ||
  +error "Command '$1' is required" )
+assert-cmd-ver() ( +is-cmd-ver "$@" ||
  +error "Command '$1' version '$2' or higher is required" )
+assert-perl() ( +assert-cmd-ver perl ${1:-5.10.1} )
+assert-git()  ( +assert-cmd-ver git  ${1:-2.7}    )
+assert-sed()  ( +assert-cmd     sed               )

# Get the absolute path of a dirname
+dirname() (
  cd "$(dirname "$1")" || exit
  pwd -P
)

# Get the absolute path of a directory
+dirpath() (
  cd "$1" || exit
  pwd -P
)

# Red die with 'Error: ' prefix
+error() { die --red "Error: $1"; }

# Check the current Bash is a minimal version.
+is-bash32+() ( shopt -s compat31 2>/dev/null )
+is-bash40+() ( shopt -s compat32 2>/dev/null )
+is-bash41+() ( shopt -s compat40 2>/dev/null )
+is-bash42+() ( shopt -s compat41 2>/dev/null )
+is-bash43+() ( shopt -s compat42 2>/dev/null )
+is-bash44+() ( shopt -s compat43 2>/dev/null )
+is-bash50+() ( shopt -s compat44 2>/dev/null )
+is-bash51+() ( t() ( local x; local -p ); [[ $(t) ]] )

# Check if command exists and is at or above a version.
+is-cmd-ver() (
  command=$1 version=$2

  out=$("$command" --version 2>/dev/null) ||
    return

  [[ $out =~ ([0-9]+\.[0-9]+(\.[0-9]+)?) ]] || {
    echo "Can't determine version number from '$command'" >&2
    return 1
  }

  IFS=. read -r -a got <<< "${BASH_REMATCH[1]}"
  : "${got[2]:=0}"

  IFS=. read -r -a want <<<"$version"
  : "${want[0]:=0}"
  : "${want[1]:=0}"
  : "${want[2]:=0}"

  (( got[0] > want[0] ||
    (( got[0] == want[0] &&
      (( got[1] > want[1] ||
        (( got[1] == want[1] && got[2] >= want[2] ))
      ))
    ))
  ))
)

# Check if a file or directory is empty
+is-empty() (
  path=${1?}
  if [[ -f $path ]]; then
    ! [[ -s $path ]]
  elif [[ -d $path ]]; then
    ! [[ $(shopt -s nullglob; printf '%s' *) ]]
  else
    die "'$path' is not a file or directory"
  fi
)

# Check if 2 files are the same or different.
+is-file-same() ( diff -q "$1" "$2" &>/dev/null )
+is-file-diff() ( ! +is-file-same "$@" )

# Check if internet is reachable.
+is-online() ( ping -q -c1 8.8.8.8 &>/dev/null )

# Check if running in a GHA workflow environment.
+in-gha() { [[ ${GITHUB_ACTIONS-} == true ]]; }

# mktemp files and dirs that automatically get deleted at end of scope.
+mktemp() {
  local temp
  temp=$(mktemp "$@")
  if [[ -d $temp ]]; then
    chmod '=rwx' "$temp"
  else
    chmod '=rw' "$temp"
  fi
  +trap "[[ -d '$temp' ]] && rm -fr '$temp' || rm -f '$temp'"
  echo "$temp"
}

# XXX Move to bashplus
# Get file modification time in epoch seconds
if +os-macos; then
  +mtime() ( stat -f %m "$1" )
else
  +mtime() ( stat -c %Y "$1" )
fi

# Add one or more directories to the front of PATH.
+path() {
  _PATH_=${_PATH_:-PATH}
  if [[ $# -eq 0 ]]; then
    (IFS=:; printf '%s\n' ${!_PATH_})
  else
    local dir dirs
    for dir in $(+reverse "$@"); do
      dirs=($(+path | grep -v "$dir"))
      set -- "$dir" "${dirs[@]}"
      printf -v "$_PATH_" '%s' "$(IFS=:; echo "$*")"
      export "$_PATH_"
    done
  fi
}

# Reverse inputs
+reverse() (
  i=$(( $# ))
  while (( i > 0 )); do
    echo "${!i}"
    i=$((i - 1))
  done
)

# Sort in true ascii order.
+sort() ( LC_ALL=C sort "$@" )

# Generate a unique symbol by joining a prefix (default is 'sym') to a random
# string, separated by an underscore (`_`) character.
# Useful for unique variable and function names.
# Here we define 6 different ways to generate a random string, since there is
# no standard way to do this in Bash 3.2+.

# For 5.0+ use EPOCHREALTIME unless it is already spoiled.
if [[ ${EPOCHREALTIME-} != "${EPOCHREALTIME-}" ]]; then
  # prevent `unset EPOCHREALTIME` which spoils it:
  readonly EPOCHREALTIME
  # This is fastest by far:
  +sym() {
    echo "${1:-sym_}_${EPOCHREALTIME/./_}"
  }
# uuidgen is pretty standard and pretty fast
elif +can uuidgen; then
  +sym() (
    s=$(uuidgen)
    echo "${1:-sym}_${s//-/_}"
  )
# BSD date (macOS) doesn't support nanoseconds
elif date --version &>/dev/null; then
  +sym() (
    echo "${1:-sym}_$(date '+%s_%N')"
  )
# `od` is super common but check for /dev/urandom
elif +can od && [[ -e /dev/urandom ]]; then
  +sym() (
    echo "${1:-sym}_$(printf '%s' $(od -A n -t x2 -N 16 /dev/urandom))"
  )
# Bash's RANDOM is 3.2+ but can also be spoiled by unset.
elif [[ ${RANDOM}_${RANDOM} != ${RANDOM}_${RANDOM} ]]; then
  readonly RANDOM
  +sym() (
    echo "${1:-sym_}_${RANDOM}_${RANDOM}_${RANDOM}_${RANDOM}"
  )
# Try perl
elif +is-cmd perl; then
  +sym() (
    echo "${1:-sym_}_$(
      perl -MTime::HiRes -e 'print join "_", Time::HiRes::gettimeofday'
    )"
  )
else
  die "bashplus can't define '+sym'"
fi

# Get current time in epoch seconds
+time() ( date +%s )

# Allow multiple traps to be performed.
+trap() {
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

# Check if first x.x.x version is greater than the second.
+version-ge() (
  IFS=. read -r -a v1 <<<"$1"
  IFS=. read -r -a v2 <<<"$2"

  (( v1[0] > v2[0] ||
    (( v1[0] == v2[0] &&
      (( v1[1] > v2[1] ||
        (( v1[1] == v2[1] && v1[2] >= v2[2] ))
      ))
    ))
  ))
)

# Check if first x.x.x version is greater than the second.
+version-gt() (
  IFS=. read -r -a v1 <<<"$1"
  IFS=. read -r -a v2 <<<"$2"

  (( v1[0] > v2[0] )) ||
  (( v1[1] > v2[1] )) ||
  (( v1[2] > v2[2] ))
)
