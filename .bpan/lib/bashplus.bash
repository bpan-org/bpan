# bashplus -- A collection of useful and portable functions:
#
# * All function names start with `+` so easy to recognize they are bashplus.
# * Many are improved versions of existing builtins/commands.

# Check if name is a callable function or command.
+can() {
  +is-func "${1:?+can requires a function name}" || +is-cmd "$1"
}

# Check the current Bash is a minimal version.
+is-bash32+() ( shopt -s compat31 2>/dev/null )
+is-bash40+() ( shopt -s compat32 2>/dev/null )
+is-bash41+() ( shopt -s compat40 2>/dev/null )
+is-bash42+() ( shopt -s compat41 2>/dev/null )
+is-bash43+() ( shopt -s compat42 2>/dev/null )
+is-bash44+() ( shopt -s compat43 2>/dev/null )
+is-bash50+() ( shopt -s compat44 2>/dev/null )
+is-bash51+() ( t() ( local x; local -p ); [[ $(t) ]] )

# Check if a name is a command.
+is-cmd() {
  [[ $(command -v "${1:?+is-cmd requires a command name}") ]]
}

# Check if command exists and is at or above a version.
+is-cmd-ver() (
  command=$1 version=$2

  out=$("$command" --version) ||
    { echo "Failed to run '$command --version'" >&2; exit 1; }

  [[ $out =~ ([0-9]+\.[0-9]+(\.[0-9]+)?) ]] ||
    die "Can't determine version number from '$command'"
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

# Check if 2 files are the same or different.
+is-file-same() ( diff -q "$1" "$2" &>/dev/null )
+is-file-diff() ( ! +is-file-same "$@" )

# Check if name is a function.
+is-func() {
  [[ $(type -t "${1:?+is-func requires a function name}") == function ]]
}

# Check if internet is reachable.
+is-online() ( ping -q -c1 8.8.8.8 &>/dev/null )

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

# Add one or more directories to PATH.
+path() {
  local i
  for (( i = $#; i >=1; i-- )); do
    PATH=${!i}:$PATH
  done
  export PATH
}

# Sort in true ascii order.
+sort() (
  LC_ALL=C sort
)

# Generate a unique symbol.
# Useful for unique variable and function names.
if +can uuidgen; then
  +sym() (
    s=$(uuidgen "${1:-'--random'}")
    echo "${1:-sym}_${s//-/_}"
  )
else
  +sym() (
    s=$(date '+%s_%N')
    echo "${1:-sym}_${s//-/_}"
  )
fi

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

