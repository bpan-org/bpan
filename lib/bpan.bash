#!/bash

# Set Bash strict settings:
set -e -u -o pipefail
shopt -s inherit_errexit 2>/dev/null || true

bpan:main() {
  local self root
  self=${BASH_SOURCE[0]}
  [[ $(dirname "$self") == */.bpan/lib ]] ||
    bpan:die "bpan.bash is in an unsupported place!"
  root=$(cd "$(dirname "$self")/../.." && pwd -P)
  local_root=$(cd "$(dirname "$self")/../../.." && pwd)

  export PATH=$root/.bpan/lib:$root/.bpan/bin:$PATH

  bpan:config-read "$root/.bpan/config"

  BPAN_VERSION="$(bpan:config bpan.version)"

  local arg
  for arg; do
    if [[ $arg == -- ]]; then
      :
    elif [[ $arg == --prelude ]]; then
      bpan:use prelude
    else
      bpan:die "Unknown argument '$arg' for '$self'"
    fi
  done
}

bpan:die() ( printf '%s\n' "$@" >&2; exit 1 )

bpan:use() {
  local library=$1; shift
  source "$library.bash" "$@"
}

bpan:config() (
  if [[ $# -eq 1 ]]; then
    if [[ $1 == *.* ]]; then
      git config -f- "$1" <<<"$config" 2>/dev/null || true
    else
      (
        git config -lf- <<<"$config" 2>/dev/null |
          grep "^$1=" |
          cut -d= -f2
      ) || true
    fi
  elif [[ $# -eq 2 ]]; then
    git config -f "$config_file" "$@"
    perl -pi -e 's/^\t//' "$config_file"
  fi
)

bpan:config-read() {
  config=''
  config_file=${1:-.bpan/config}
  if [[ -f $config_file ]]; then
    config_file=$(readlink -f "$config_file")
    config=$(< "$config_file")
    local from_file
    from_file=$(bpan:config from)
    if [[ $from_file ]]; then
      config=$(
        cd "$(dirname "$config_file")"
        cat "$from_file"
        echo
        echo "$config"
      )
      config_file=$from_file
    fi
  else
    config_file=''
  fi
}

bpan:require-commands() (
  while read -r line; do
    [[ $line ]] || break
    command=${line#require.commands.}
    version=${command#*=}
    version=${version%+}
    command=${command%%=*}
    require-command-version "$command" "$version"
  done < <(
    bpan:config-read
    git config -lf- <<<"$config" |
      grep "^require\.command\."
  )
)

bpan:main "$@"
