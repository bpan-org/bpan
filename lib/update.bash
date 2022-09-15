: "
bpan update --all
- Update all files 
bpan update --file=Makefile


"

update:options() (
  echo "l,list    List files to update"
  echo "f,file    File to update"
  echo "t,type=   pkg | file | man | new | init | global"
  echo "a,all     All types"
  echo "I,index   Refresh index file"
  echo "L,local   Symlink install to local repos"
)

update:main() (
  update:file
  update:require
  update:man
)

update:file() (
  while read -r file; do
    :
  done < <(
    config:list |
      grep -E '^file.bpan.update'
  )
)

update:require() (
  [[ -d .bpan ]] ||
    error "Can't 'bpan update'. No '.bpan/' directory"

  source-once pkg
  source-once install

  (
    file=lib/bpan.bash
    if [[ -f .bpan/$file ]] &&
      ! [[ -h .bpan/$file ]]
    then
      (
        say-y "Updating '.bpan/$file'"
        $option_verbose && set -x
        cp -Lp "$root/$file" ".bpan/$file"
      )
    fi
  )

  while read -r pkg; do
    pkg=${pkg#require.bpan.}
    pkg=${pkg#require.test.}
    pkg=${pkg%%=*}

    $option_local ||
      install:main "$pkg"
    option_index=false
    pkg:parse-id "$pkg"
    if ! $option_local; then
      if [[ ! $ver ]]; then
        src+=$(pkg:get-version "$full")
      fi
    fi

    while read -r file; do
      rm -f ".bpan/$file"
      mkdir -p "$(dirname ".bpan/$file")"

      if $option_local; then
        (
          say-y "Updating '.bpan/$file' -> '$local_root/$name/$file' (local)"
          $option_verbose && set -x
          ln -s "$local_root/$name/$file" ".bpan/$file"
        )
      else
        n=${file//[^\/]/}
        n=${#n}
        prefix=..
        for (( i = 1; i < n; i++ )); do prefix+=/..; done

        (
          say-y "Updating '.bpan/$file' from '$root/local/$file'"
          $option_verbose && set -x
          cp -Lp "$root/local/$file" ".bpan/$file"
        )
      fi
    done < <(
      cd "$src" || exit
      find bin lib share -type f 2>/dev/null || true
    )

  done < <(
    config:list |
      grep -E '^require\.(bpan|test)\.'
  )
)

update:man() (
  [[ -d doc ]] || return 0

  if ! +is-cmd md2man; then
    say -r "Run 'bpan install md2man' to update man pages"
    return
  fi

  # shellcheck disable=2044
  for md in $(find doc -type f -name '*.md'); do
    name=${md#doc/}
    name=${name%.md}
    num=3
    if [[ -f bin/$name ]]; then
      num=1
    fi
    mkdir -p "man/man$num"
    man=man/man$num/$name.$num

    MD2MAN_NUM=$num
    MD2MAN_NAME=$name
    MD2MAN_DESC=$(bpan config bpan.abstract)
    MD2MAN_PROG="md2man v0.1.0"
    export MD2MAN_NUM MD2MAN_NAME MD2MAN_DESC MD2MAN_PROG

    say -y "Updating '$man' from '$md'"
    "$root/local/bin/md2man" < "$md" > "$man"
  done
)
