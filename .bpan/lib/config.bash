config_file=''
config_files=()

config:get() (
  [[ $# -gt 0 ]] ||
    config:die "config:get requires 1 or more keys"
  [[ $config_file ]] && config_files=( "$config_file" )
  config=$(cat "${config_files[@]?}")
  for key; do
    if value=$(git config -f- "$key" <<<"$config"); then
      i=0
      while [[ $value =~ \$([.a-z0-9]+) ]]; do
        repl=$(git config -f- "${BASH_REMATCH[1]}" <<<"$config") ||
          config:die "Can't expand config value '$key'"
        value=${value//\$${BASH_REMATCH[1]}/$repl}
        [[ $((i++)) -lt 10 ]] ||
          config:die "Possible infinite recursion in config value '$key'"
      done
      echo "$value"
      return
    fi
  done
  return 1
)

config:set() (
  [[ $config_file ]] && config_files=( "$config_file" )
  [[ $# -eq 2 ]] ||
    config:die "config:set requires 2 arguments: key/value"
  file=${config_files[-1]?}
  git config --file "$file" "$@"
  sed -i 's/^\t//' "$file"
)

config:all() (
  [[ $config_file ]] && config_files=( "$config_file" )
  [[ $# -eq 1 ]] ||
    config:die "config:all requires 1 key"
  git config --file <(cat "${config_files[@]?}") --get-all "$@"
)

config:list() (
  [[ $config_file ]] && config_files=( "$config_file" )
  git config --file <(cat "${config_files[@]?}") --list |
    sort
)

config:die() (
  echo "$*" >&2
  exit 1
)
