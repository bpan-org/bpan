misc:main() (
  shift
  cmd=${1:-}
  [[ $cmd ]] ||
    error "$app + requires a command word"
  shift

  +can "misc:$cmd" ||
    error "No 'bpan +' command '$cmd'"

  "misc:$cmd" "$@"
)

misc:stamp() (
  echo "$bpan_timestamp"
)

misc:sha512() (
  ref=${1:-HEAD}
  {
    printf 'commit %s\0' "$(
      git --no-replace-objects cat-file commit "$ref" | wc -c
    )"
    git cat-file commit HEAD
  } |
    sha512sum |
    cut -d' ' -f1
)
