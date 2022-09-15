+path() {
  local i
  for (( i = $#; i >=1; i-- )); do
    PATH=${!i}:$PATH
  done
  export PATH
}

+is-bash32+() ( shopt -s compat31 2>/dev/null )
+is-bash40+() ( shopt -s compat32 2>/dev/null )
+is-bash41+() ( shopt -s compat40 2>/dev/null )
+is-bash42+() ( shopt -s compat41 2>/dev/null )
+is-bash43+() ( shopt -s compat42 2>/dev/null )
+is-bash44+() ( shopt -s compat43 2>/dev/null )
+is-bash50+() ( shopt -s compat44 2>/dev/null )
+is-bash51+() ( t() ( local x; local -p ); [[ $(t) ]] )

+is-online() ( ping -q -c1 8.8.8.8 &>/dev/null )

+can() {
  +is-func "${1:?+can requires a function name}" || +is-cmd "$1"
}

+is-func() {
  [[ $(type -t "${1:?+is-func requires a function name}") == function ]]
}

+is-cmd() {
  [[ $(command -v "${1:?+is-cmd requires a command name}") ]]
}

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
