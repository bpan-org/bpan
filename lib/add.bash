add:default() (
  echo --help
)

add:usage() (
  echo "$app [<opts>] $cmd <$cmd-opts> <pkg...>"
)

add:options() (
  echo "I,index   Refresh index file"
)

add:main() (
  source-once pkg
  update=false

  for pkg; do
    pkg:parse-id+ "$pkg"
    ver=$ver+
    previous=$(bpan:config "require.bpan.$pkg")
    if [[ $previous == "$ver" ]]; then
      say-y "'require.bpan.$pkg=$ver' is already in '$config_file'"
      continue
    fi
    bpan:config "require.bpan.$pkg" "$ver"
    update=true
    if [[ $previous ]]; then
      say-y "Updated 'require.bpan.$pkg=$ver' in '$config_file'"
    else
      say-y "Added 'require.bpan.$pkg=$ver' to '$config_file'"
    fi
  done

  if $update; then
    source-once update
    update:main
  fi
)
