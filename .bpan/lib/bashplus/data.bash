# Size of list:
+l:count() ( echo $# )

# Apply a function to each elem in a list:
+l:each() {
  local fun=${1?}; shift
  +can "$fun" ||
    die "'$fun' is not a function or command"
  local elem
  for elem; do
    "$fun" "$elem"
  done
}

# Reverse a list:
+l:reverse() (
  for (( i = $#; i > 0; i-- )); do
    echo "${!i}"
  done
)

# Sort in true ascii order.
+l:sort() {
  LC_ALL=C sort "$@"
}
