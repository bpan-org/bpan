config:init() {
  __config_files=("$@")
  __config_from=''
  __config_data=''
  unset config_file  # XXX
  config:data
}

config:get() (
  set +x
  config:data "$@"
  [[ ${#args[*]} -gt 0 ]] ||
    config:die "config:get requires 1 or more keys"
  for key in "${args[@]}"; do
    if value=$(git config -f- "$key" <<<"$__config_data"); then
      i=0
      while [[ $value =~ \$([.a-z0-9]+) ]]; do
        repl=$(git config -f- "${BASH_REMATCH[1]}" <<<"$__config_data") ||
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
  set +x
  config:data "$@"
  [[ ${#args[*]} -eq 2 ]] ||
    config:die "config:set requires 2 arguments: key/value"
  file=${__config_files[-1]?}
  git config --file "$file" "${args[@]}"
  config:untab "$file"
  __config_data=''
)

config:add() (
  set +x
  config:data "$@"
  [[ ${#args[*]} -eq 2 ]] ||
    config:die "config:add requires 2 arguments: key/value"
  file=${__config_files[-1]?}
  git config --file "$file" --add "${args[@]}"
  config:untab "$file"
  __config_data=''
)

config:all() (
  set +x
  config:data "$@"
  [[ ${#args[*]} -eq 1 ]] ||
    config:die "config:all requires 1 key"
  git config --file <(cat "${__config_files[@]?}") --get-all "${args[@]}"
)

config:list() (
  set +x
  config:data "$@"
  git config --file <(cat "${__config_files[@]?}") --list |
    LC_ALL=C sort
)

#------------------------------------------------------------------------------
config:data() {
  args=()

  [[ ${config_file-} ]] && die --level=2 12345  # XXX

  local reset=false
  while [[ $# -gt 0 ]]; do
    if [[ $1 == --file=* ]]; then
      if $reset; then
        __config_files+=("${1#--file=}")
      else
        __config_files=("${1#--file=}")
        reset=true
      fi
    else
      args+=("$1")
    fi
    shift
  done

  [[ ${#__config_files[*]} -gt 0 ]] ||
    config:die \
      "Error using 'config:*' function." \
      "Internal variable '__config_files' array is empty." \
      "Call 'config:init <file...>' first" \
      "See: https://bpan.errgo.io/AB3D"
  local from
  from=$(IFS=:; echo "${__config_files[@]}")
  if [[ $from == "$__config_from" && $__config_data ]]; then
    return
  fi
  __config_from=$from
  __config_data=$(cat "${__config_files[@]?}")
}

config:untab() (
  for file; do
    text=$(< "$file")
    echo "${text//$'\t'/}" > "$file"
  done
)

config:die() {
  set +x
  printf '%s\n' "$@" >&2
  exit 1
}
