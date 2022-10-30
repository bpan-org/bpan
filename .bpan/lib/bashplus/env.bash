# shellcheck disable=2086,2119,2120

# Add one or more directories to the front of PATH.
+env:path() {
  _PATH_=${_PATH_:-PATH}
  if [[ $# -eq 0 ]]; then
    (IFS=:; printf '%s\n' ${!_PATH_})
  else
    local i
    for (( i = $#; i >= 1; i-- )); do
      local dirs=($(+env:path | grep -v "${!i}"))
      printf -v "$_PATH_" '%s' "$(IFS=:; echo "${!i}:${dirs[*]}")"
    done
    export "${_PATH_?}"
  fi
}
