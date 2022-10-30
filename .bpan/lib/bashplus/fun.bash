+source bashplus/sym

# Check if name is a function.
+fun:ok() [[
  $(type -t "${1:?+fun:ok requires a function name}") == function ]]

# Make a function anonymous
+fun:anon() {
  local fun=${1?}
  local var=${2?}
  local anon
  anon=$(+sym)
  +fun:copy "$fun" "$(+sym)"
  unset -f "$fun"
  printf -v "$var" '%s' "$anon"
}

# A function that wraps functions with other functions:
+fun:copy() {
  local code
  code=$(type "${1?}")
  eval "${2?}${code#$1 is a function$'\n'$1}"
}

# A function that wraps functions with other functions:
+fun:wrap() {
  local func_name func_code wrap_name wrap_code anon_name anon_code
  wrap_name=${1?}; shift
  wrap_code=$(type "$wrap_name")
  for func_name; do
    anon_name=$(+sym)
    func_code=$(type "$func_name")
    func_code=$anon_name${func_code#$func_name is a function$'\n'$func_name}
    anon_code=$func_name${wrap_code#$wrap_name is a function$'\n'$wrap_name}
    anon_call=$func_code$'\n'$anon_name' "$@"'
    eval "${anon_code/::function::/$anon_call}"
  done
}
