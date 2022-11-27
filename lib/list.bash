list:main() (
  source-once util/db

  if [[ ! -d $install_dir/src ]]; then
    say -r "No BPAN packages currently installed"
    return
  fi

  read -r -a installed <<<"$(db:list-installed)"

  if [[ ${#installed[*]} -eq 0 ]]; then
    say -r "No BPAN packages currently installed"
    return
  fi

  for id in "${installed[@]}"; do
    if db:package-is-primary "$id"; then
      say -g "* $id"
    else
      say -y "  $id"
    fi

    if $option_verbose; then
      list:links "$id"
    fi
  done
)
