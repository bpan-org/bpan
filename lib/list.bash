list:main() (
  source-once util/pkg

  if [[ ! -d $BPAN_INSTALL/src ]]; then
    say -r "No BPAN packages currently installed"
    return
  fi

  installed=($(pkg:installed))

  if [[ ${#installed[*]} -eq 0 ]]; then
    say -r "No BPAN packages currently installed"
    return
  fi

  for id in "${installed[@]}"; do
    if pkg:is-primary "$id"; then
      say -g "* $id"
    else
      say -y "  $id"
    fi

    if $option_verbose; then
      list:links "$id"
    fi
  done
)

list:links() (
  id=$1
  die ">>$id<<"
)
