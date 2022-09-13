# prelude - A Modern Bash Prelude
#
# Copyright (c) 2022 Ingy döt Net

is-func() {
  [[ $(type -t "${1:?is-func requires a function name}") == function ]]
}

is-cmd() {
  [[ $(command -v "${1:?is-cmd requires a command name}") ]]
}

can() {
  is-func "$1" || is-cmd "$1"
}

require-command-version() (
  command=$1 version=$2

  [[ $(command -v "$command") ]] ||
    die "Error: command '$command' is required but not found"

  check-command-version "$command" "$version" ||
    die "Error: command '$command' version '$version' required"
)

check-command-version() (
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

# XXX Move to bashplus
path+() {
  local i
  for (( i = $#; i >=1; i-- )); do
    PATH=${!i}:$PATH
  done
  export PATH
}
