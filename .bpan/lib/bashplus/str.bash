+str:repeat() {
  printf -- "${1:-\ }%.0s" $(seq "${2:-1}")
}

+str:trim() {
  local s=${1#"${1%%[![:space:]]*}"}
  echo "${s%"${s##*[![:space:]]}"}"
}

+str:trim-left() {
  echo "${1#"${1%%[![:space:]]*}"}"
}

+str:trim-right() {
  echo "${1%"${1##*[![:space:]]}"}"
}
