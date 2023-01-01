ini:version() ( echo "0.1.15" )

ini:init() {
  if [[ $# -gt 0 ]]; then
    __ini_files=("$@")
  elif [[ ${#__ini_files[*]} -eq 0 ]]; then
    ini:die "ini:init called without ini files"
  fi
  __ini_from=''
  __ini_data=''
  __ini_vars=()
  ini:data
}

ini:files() {
  ini:init "$@"
}

ini:vars() {
  __ini_vars=("$@")
}

ini:get() {
  local set=$-; set "${BPAN_X:-+x}"
  local __ini_files=("${__ini_files[@]}")
  local args i key value var val
  ini:data "$@"
  [[ ${#args[*]} -gt 0 ]] ||
    ini:die "ini:get requires 1 or more keys"
  for key in "${args[@]}"; do
    if value=$(git config -f- "$key" <<<"$__ini_data"); then
      i=0
      while [[ $value =~ \$([-_.a-zA-Z0-9]+) ]]; do
        var=${BASH_REMATCH[1]}
        val=$(git config -f- "$var" <<<"$__ini_data" 2>/dev/null || true)
        if [[ ! $val &&
              " ${__ini_vars[*]} " == *" $var "*
        ]]; then
          val=${!var-}
        fi
        [[ $val ]] ||
          ini:die "Can't expand ini value '$key=$value'"
        value=${value//\$$var/$val}
        [[ $((i++)) -lt 10 ]] ||
          ini:die "Possible infinite recursion in ini value '$key'"
      done
      echo "$value"
      [[ $set != *x* ]] || set -x
      return 0
    fi
  done
  [[ $set != *x* ]] || set -x
  return 1
}

ini:set() {
  local set=$-; set "${BPAN_X:-+x}"
  local __ini_files=("${__ini_files[@]}")
  local args i file
  ini:data "$@"
  [[ ${#args[*]} -eq 2 ]] ||
    ini:die "ini:set requires 2 arguments: key/value"
  i=${#__ini_files[*]}
  file=${__ini_files[i-1]?}
  git config --file "$file" "${args[@]}"
  ini:format "$file"
  __ini_data=''
  [[ $set != *x* ]] || set -x
}

ini:add() {
  local set=$-; set "${BPAN_X:-+x}"
  local __ini_files=("${__ini_files[@]}")
  local args i file
  ini:data "$@"
  [[ ${#args[*]} -eq 2 ]] ||
    ini:die "ini:add requires 2 arguments: key/value"
  i=${#__ini_files[*]}
  file=${__ini_files[i-1]?}
  git config --file "$file" --add "${args[@]}"
  ini:format "$file"
  __ini_data=''
  [[ $set != *x* ]] || set -x
}

ini:all() (
  set "${BPAN_X:-+x}"
  ini:data "$@"
  [[ ${#args[*]} -eq 1 ]] ||
    ini:die "ini:all requires 1 key"
  git config --file <(cat "${__ini_files[@]?}") --get-all "${args[@]}"
)

ini:list() (
  set "${BPAN_X:-+x}"
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

ini:format() {
  local file text
  for file; do
    text=$(< "$file")
    text=${text//$'= \n'/$'= ""\n'}
    echo "${text//$'\t'/}" > "$file"
  done
}

ini:die() {
  printf '%s\n' "$@" >&2
  exit 1
}
