update:options() (
  echo "l,list    List possible template files"
  echo "f,file=   Template file to update"
  echo "t,type=   pkg | file | man | new | init | global"
  echo "a,all     All types"
  echo "I,index   Refresh index file"
  echo "L,local   Symlink install to local repos"
)

update:main() (
  if $option_list; then
    update:list

  else
    source-once install
    source-once pkg

    [[ -d .bpan ]] ||
      error "Can't 'bpan update'. No '.bpan/' directory"

    index_file=$BPAN_INSTALL/index.ini
    pkg:get-index

    update:files
    update:require
    update:man
  fi
)

update:list() (
  cd "$BPAN_ROOT/share/update" || exit
  find . -type l |
    +sort |
    cut -c3-
)

update:files() (
  source-once file
  name=$(config:get package.name)
  while read -r line; do
    line=${line#file.bpan.}
    action=${line%%=*}
    file=${line#*=}

    if [[ $file == *\ * ]]; then
      IFS=' ' read -r to from <<<"$file"
    else
      from=$BPAN_ROOT/share/update/$file
      to=$file
    fi

    if [[ -e $to ]]; then
      file:copy "$from" "$to"
    fi
  done < <(
    config:list |
      grep '^update\.template'
  )
)

update:require() (
  (
    file=lib/bpan.bash
    if [[ -f .bpan/$file ]] &&
      ! [[ -h .bpan/$file ]]
    then
      from=$root/$file
      to=.bpan/$file
      if +is-file-same "$to" "$from"; then
        say-y "CURRENT '$to'"
      else
        (
          $option_verbose && set -x
          cp -Lp "$from" "$to"
        )
        say-y "UPDATED '$to'"
      fi
    fi
  )

  while read -r pkg; do
    pkg=${pkg#*=}

    pkg:parse-id+ "$pkg"

    if ! $option_local &&
       ! [[ -d $src ]]
    then
      say -y "INSTALL $owner/$name $ver"
      install:main "$pkg"
    fi

    option_index=false
    pkg:parse-id "$pkg"
    if ! $option_local; then
      if [[ ! $ver ]]; then
        src+=$(pkg:get-version "$full")
      fi
    fi

    while read -r file; do
      mkdir -p "$(dirname ".bpan/$file")"

      if $option_local; then
        (
          $option_verbose && set -x
          ln -s "$local_root/$name/$file" ".bpan/$file"
          say-y "UPDATED '.bpan/$file' -> '$local_root/$name/$file' (local)"
        )
      else
        n=${file//[^\/]/}
        n=${#n}
        prefix=..
        for (( i = 1; i < n; i++ )); do prefix+=/..; done

        from=$root/local/$file
        to=.bpan/$file
        if [[ -h $to ]] ||
           +is-file-diff "$to" "$from"
        then
          (
            $option_verbose && set -x
            rm -f "$to"
            cp -Lp "$from" "$to"
          )
          say-y "UPDATED '$to' from '$from'"
        else
          say-y "CURRENT '$to'"
        fi
      fi
    done < <(
      cd "$src" || exit
      find bin lib share -type f 2>/dev/null || true
    )

  done < <(
    config:list |
      grep '^update\.package'
  )
)

update:man() (
  [[ -d doc ]] || return 0

  if ! +is-cmd pandoc; then
    say -r "Can't update man pages. Need 'pandoc'." >&2
    return
  fi

  if ! +is-cmd md2man; then
    install:main md2man
  fi

  # shellcheck disable=2044
  while read -r md; do
    md=${md#*=}
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
    MD2MAN_DESC=$(bpan config package.title)
    MD2MAN_PROG="md2man v0.1.0"
    export MD2MAN_NUM MD2MAN_NAME MD2MAN_DESC MD2MAN_PROG

    temp=$(+mktemp)
    "$root/local/bin/md2man" < "$md" > "$temp"
    if +is-file-same "$man" "$temp"; then
      say -y "CURRENT '$man'"
    else
      mv "$temp" "$man"
      say -y "UPDATED '$man' from '$md'"
    fi
  done < <(
    config:list |
      grep '^update\.manpage'
  )
)
