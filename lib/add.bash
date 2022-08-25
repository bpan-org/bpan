add:getopt() {
  getopt_spec="\
$app [<$app-opts>] $command <pkg...>

'$app $command' Options:
--
h,help        Get help for $command command
"
}

add:main() (
  source1 install
  option_local=false
  update=false

  for pkg; do
    install:parse-vars "$pkg"
    ref=$ref+
    previous=$(bpan:config "require.bpan.$pkg")
    if [[ $previous == $ref ]]; then
      echo-y "'require.bpan.$pkg=$ref' is already in '$config_file'"
      continue
    fi
    bpan:config "require.bpan.$pkg" "$ref"
    update=true
    if [[ $previous ]]; then
      echo-y "Updated 'require.bpan.$pkg=$ref' in '$config_file'"
    else
      echo-y "Added 'require.bpan.$pkg=$ref' to '$config_file'"
    fi
  done

  if $update; then
    source1 update
    update:main
  fi
)
