+source bashplus/sym

# Check if name is a function.
+func:ok() [[
  $(type -t "${1:?+func:ok requires a function name}") == function ]]

# List all functions (possibly matching a pattern):
+func:list() (
  declare -F |
    cut -d' ' -f3 |
    if [[ ${1-} ]]; then
      grep -E "$1"
    else
      cat
    fi
)

# Make a function anonymous:
+func:anon() {
  local func=${1?}
  local var=${2?}
  local anon
  anon=$(+sym)
  +func:copy "$func" "$(+sym)"
  unset -f "$func"
  printf -v "$var" '%s' "$anon"
}

# A function that wraps functions with other functions:
+func:copy() {
  local code
  code=$(type "${1?}")
  eval "${2?}${code#$1 is a function$'\n'$1}"
}

# A function that wraps functions with other functions:
+func:wrap() {
  local func_name func_code wrap_name wrap_code anon_name anon_code
  wrap_name=${1?}; shift
  wrap_code=$(type "$wrap_name")
  for func_name; do
    anon_name=$(+sym)
    func_code=$(type "$func_name")
    func_code=$anon_name${func_code#$func_name is a function$'\n'$func_name}
    anon_code=$func_name${wrap_code#$wrap_name is a function$'\n'$wrap_name}
    anon_call=$func_code$'\n'$anon_name' "$@"'
    anon_code=${anon_code/::FUNC-CALL::/$anon_call}
    anon_code=${anon_code/::FUNC-NAME::/$func_name}
    eval "$anon_code"
  done
}
