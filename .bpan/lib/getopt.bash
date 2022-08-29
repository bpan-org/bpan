# getopt-long library based around `git rev-parse --parseopt`

[[ ${1-} ]] && getopt=$1

getopt() {
  local opts_prefix=option
  local args_var=
  local default_arg='--help'
  local catch_error=false

  local getopt_spec
  getopt_spec=${GETOPT_SPEC:-${getopt:-$(cat)}}

  [[ $getopt_spec ]] ||
    die "No getopt 'spec' provided"

  local spec
  spec=$(
    echo "$getopt_spec" |
      grep -A999999 '^--$' |
      grep -v '^\s*$' |
      tail -n+2
  )

  if ${getopt_default_help:-true}; then
    if [[ $# -eq 0 ]];then
      set -- --help
    fi
  fi

  local parsed
  parsed=$(
    echo "$getopt_spec" |
      git rev-parse --parseopt -- "$@"
  ) || true

  if [[ $parsed =~ ^cat ]]; then
    eval "$parsed" | getopt:pager
    exit 0
  else
    eval "$parsed"
  fi

  while IFS= read -r line; do
    if [[ $line =~ ^([-a-zA-Z]+)(,([-a-z]+))?(=?)\  ]]; then
      opt_var=option_${BASH_REMATCH[1]}
      if [[ ${BASH_REMATCH[3]} ]]; then
        opt_var=option_${BASH_REMATCH[3]}
      fi
      opt_var=${opt_var//-/_}
      if [[ -z ${BASH_REMATCH[4]} ]]; then
        printf -v "$opt_var" false
      else
        lines_var=${opt_var}_lines
        if [[ ${!lines_var-} ]]; then
          eval "$opt_var+=()"
        fi
      fi
    fi
  done <<<"$spec"

  while [[ $# -gt 0 ]]; do
    local option=$1; shift

    [[ $option != -- ]] || break

    local found=false line=
    while IFS= read -r line; do
      local wants_value=false match opt_var
      if [[ $line =~ ^([-a-zA-Z]+)(,([-a-z]+))?(=?)\  ]]; then
        if [[ ${#BASH_REMATCH[1]} -gt 1 ]]; then
          match=--${BASH_REMATCH[1]}
        else
          match=-${BASH_REMATCH[1]}
        fi
        opt_var=option_${BASH_REMATCH[1]}
        if [[ ${BASH_REMATCH[3]} ]]; then
          opt_var=option_${BASH_REMATCH[3]}
        fi
        opt_var=${opt_var//-/_}
        if [[ ${BASH_REMATCH[4]} ]]; then
          wants_value=true
        fi
      else
        die "Invalid getopt_spec option line: '$line'"
      fi

      if [[ $option == "$match" ]]; then
        if $wants_value; then
          lines_var=${opt_var}_lines
          if [[ ${!lines_var-} ]]; then
            eval "$opt_var+=('$1')"
          else
            printf -v "$opt_var" "%s" "$1"
          fi
          shift
        else
          printf -v "$opt_var" true
        fi
        found=true
        break
      fi
    done <<<"$spec"

    $found || die "Unexpected option: '$option'"
  done

  local i arg_name arg_var required=false array=false re1='^\+'
  for arg_name in ${getopt_args-}; do
    arg_var=${arg_name//-/_}
    if [[ $arg_var =~ ^@ ]]; then
      array=true
      arg_var=${arg_var#@}
      printf -v "$arg_var"'[0]' xxx
      unset "$arg_var"'[0]'
    fi
    if [[ $arg_var =~ $re1 ]]; then
      required=true
      arg_var=${arg_var#+}
    fi

    if [[ $# -gt 0 ]]; then
      if $array; then
        for ((i = 1; i <= $#; i++)); do
          read -r "${arg_var[i-1]}" <<< "${!i}"
        done
        set --
      else
        printf -v "$arg_var" "%s" "$1"
        shift
      fi
    fi
    if $required && [[ -z ${!arg_var-} ]]; then
      die "'$arg_name' is required"
    fi
  done

  [[ $# -eq 0 ]] || die "Unexpected arguments: '$*'"
}

getopt:pager() (
  less -FRX
)
