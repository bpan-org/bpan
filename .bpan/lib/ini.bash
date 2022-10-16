ini:init() {
  __ini_files=("$@")
  __ini_from=''
  __ini_data=''
  ini:data
}

ini:files() {
  ini:init "$@"
}

ini:get() (
  set +x
  ini:data "$@"
  [[ ${#args[*]} -gt 0 ]] ||
    ini:die "ini:get requires 1 or more keys"
  for key in "${args[@]}"; do
    if value=$(git config -f- "$key" <<<"$__ini_data"); then
      i=0
      while [[ $value =~ \$([.a-z0-9]+) ]]; do
        repl=$(git config -f- "${BASH_REMATCH[1]}" <<<"$__ini_data") ||
          ini:die "Can't expand ini value '$key'"
        value=${value//\$${BASH_REMATCH[1]}/$repl}
        [[ $((i++)) -lt 10 ]] ||
          ini:die "Possible infinite recursion in ini value '$key'"
      done
      echo "$value"
      return
    fi
  done
  return 1
)

ini:set() (
  set +x
  ini:data "$@"
  [[ ${#args[*]} -eq 2 ]] ||
    ini:die "ini:set requires 2 arguments: key/value"
  file=${__ini_files[-1]?}
  git config --file "$file" "${args[@]}"
  ini:untab "$file"
  __ini_data=''
)

ini:add() (
  set +x
  ini:data "$@"
  [[ ${#args[*]} -eq 2 ]] ||
    ini:die "ini:add requires 2 arguments: key/value"
  file=${__ini_files[-1]?}
  git config --file "$file" --add "${args[@]}"
  ini:untab "$file"
  __ini_data=''
)

ini:all() (
  set +x
  ini:data "$@"
  [[ ${#args[*]} -eq 1 ]] ||
    ini:die "ini:all requires 1 key"
  git config --file <(cat "${__ini_files[@]?}") --get-all "${args[@]}"
)

ini:list() (
  set +x
  ini:data "$@"
  git config --file <(cat "${__ini_files[@]?}") --list |
    LC_ALL=C sort
)

#------------------------------------------------------------------------------
ini:data() {
  args=()

  local reset=false
  while [[ $# -gt 0 ]]; do
    if [[ $1 == --file=* ]]; then
      if $reset; then
        __ini_files+=("${1#--file=}")
      else
        __ini_files=("${1#--file=}")
        reset=true
      fi
    else
      args+=("$1")
    fi
    shift
  done

  [[ ${#__ini_files[*]} -gt 0 ]] ||
    ini:die \
      "Error using 'ini:*' function." \
      "Internal variable '__ini_files' array is empty." \
      "Call 'ini:init <file...>' first" \
      "See: https://bpan.errgo.io/AB3D"
  local from
  from=$(IFS=:; echo "${__ini_files[@]}")
  if [[ $from == "$__ini_from" && $__ini_data ]]; then
    return
  fi
  __ini_from=$from
  __ini_data=$(cat "${__ini_files[@]?}")
}

ini:untab() (
  for file; do
    text=$(< "$file")
    echo "${text//$'\t'/}" > "$file"
  done
)

ini:die() {
  set +x
  printf '%s\n' "$@" >&2
  exit 1
}
