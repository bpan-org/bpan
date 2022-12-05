register:options() (cat <<...
I,index=  Index name to register to
...
)

register:main() (
  source-once util/db

  index=$(db:index-names)
  [[ $index && $index != *$'\n'* ]] ||
    error "Can't determine index to register to." \
      "Please specify with '--index=<index-name>'."

  db:source:plugin publish register

  register:run "$@"
)

register:run() (
  error "$APP index '$index' does not support '$app register'"
)
