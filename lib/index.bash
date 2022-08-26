index:main() (
  if [[ ! -f $index_file ]] ||
     [[ $(find "$index_file" -mmin +1440) ]]
  then
    echo-y "Updating BPAN package index..."
    mkdir -p "$root/local"
    curl --fail -s "$index_url" > "$index_file" ||
      rm -f "$index_file"
  fi

  [[ -f $index_file ]] ||
    die "BPAN package index file not available"
)

index:main "$@"
