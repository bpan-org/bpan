# Size of list:
+l:count() { echo $#; }

# Apply a function to each elem in a list:
+l:each() {
  local func=${1?}; shift
  +can "$func" ||
    die "'$func' is not a function or command"
  local elem
  for elem; do
    "$func" "$elem"
  done
}

# Reverse a list:
+l:reverse() {
  local i
  for (( i = $#; i > 0; i-- )); do
    echo "${!i}"
  done
}

# Sort in true ascii order.
+l:sort() {
  LC_ALL=C sort "$@"
}
