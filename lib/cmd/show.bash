show:options() (cat <<...
c,commands    List $app commands
p,packages    List installed packages
i,indexes     List $app commands
# t,type        Type of package to list
# P,plugins     List installed plugins
# T,templates   List installed templates

q,quiet       Print only the names
...
)

show:main() (
  shown=false
  while read -r opt tail; do
    [[ $opt ]] || continue
    [[ $opt == \#* ]] && continue
    [[ $opt == q,* ]] && continue
    opt=${opt#*,}
    option=option_$opt
    if ${!option:-false}; then
      $option_quiet || say -y "### $APP $opt:"
      "show:$opt"
      $option_quiet || echo
      shown=true
    fi
  done <<<"$(show:options)"

  if ! $shown; then
    bpan-run show --help
  fi
)

show:commands() (
  i=1
  echo "$getopt_spec" |
  grep -E '^  \w+  ' |
  while read -r name desc; do
    if $option_quiet; then
      echo "$name"
    else
      printf '%2d) %-10s - %s\n' $((i++)) "$name" "$desc"
    fi
  done
)

show:packages() (
  i=1
  source-once db
  db:index-names |
  while read -r index; do
    db:get-index-info "$index"
    ini:list --file="$index_file_path" |
      grep ^host |
      cut -d. -f2
  done |
  +uniq |
  while read -r host; do
    find "$install_dir/src/" -maxdepth 4 -path '*/github/*/[0-9]*' |
      sort |
      rev |
      cut -d/ -f1-4 |
      rev |
    while IFS=/ read -r host owner name version; do
      id=$host:$owner/$name=$version
      if $option_quiet; then
        echo "$id"
      else
        config=$install_dir/src/$host/$owner/$name/$version/.bpan/config
        if [[ -f $config ]]; then
          title=$(ini:get --file="$config" package.title)
        else
          title=''
        fi
        printf '%2d) %-40s - %s\n' $((i++)) "$id" "$title"
      fi
    done
  done
)

show:indexes() (
  i=1
  source-once db
  db:index-names |
  while read -r index; do
    if $option_quiet; then
      echo "$index"
    else
      url=$(ini:get "index.$index.source")
      printf '%2d) %-10s - %s\n' $((i++)) "$index" "$url"
    fi
  done
)
