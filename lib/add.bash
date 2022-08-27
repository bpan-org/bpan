add:getopt() {
  getopt_spec="\
$app [<$app-opts>] $command <pkg...>

'$app $command' Options:
--
I,index       Refresh index file

h,help        Get help for $command command
"
}

add:main() (
  source1 pkg
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
    source1 update
    update:main
  fi
)
