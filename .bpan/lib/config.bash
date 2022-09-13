config_file=''
config_files=()

config:get() (
  [[ $config_file ]] && config_files=( "$config_file" )
  [[ $# -gt 0 ]] ||
    config:die "config:get requires 1 or more keys"
  for key; do
    if value=$(git config --file <(cat "${config_files[@]?}") "$key"); then
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
  git config --file <(cat "${config_files[@]?}") --list
)

config:die() (
  echo "$*" >&2
  exit 1
)
