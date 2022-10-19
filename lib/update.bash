update:options() (
  echo "l,list    List possible template files"
  echo "f,file=   Template file to update"
  echo "t,type=   pkg | file | man | new | init | global"
  echo "a,all     All types"
  echo "I,index   Refresh index file"
  # echo "L,local   Symlink install to local repos"
)

update:main() (
  if $option_list; then
    update:list

  else
    source-once install
    source-once pkg

    config=.bpan/config
    [[ -f $config ]] ||
      error "Can't 'bpan update'. No '$config' file."

    pkg:index-update

    update:files
    update:require
    update:man
  fi
)

update:list() (
  cd "$BPAN_ROOT/share/add" || exit
  find . -type l |
    +sort |
    cut -c3-
)

update:files() (
  source-once add
  name=$(ini:get package.name)
  while read -r line; do
    line=${line#file.bpan.}
    action=${line%%=*}
    file=${line#*=}

    if [[ $file == *\ * ]]; then
      IFS=' ' read -r to from <<<"$file"
    else
      from=$BPAN_ROOT/share/add/$file
      to=$file
    fi

    if [[ -e $to ]]; then
      add:file-copy "$from" "$to"
    fi
  done < <(
    ini:list --file=.bpan/config |
      grep '^update\.file'
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

    if ! [[ -d $src ]]; then
      say -y "INSTALL $owner/$name $ver"
      install:main "$pkg"
    fi

    option_index=false
    pkg:parse-id "$pkg"
    if [[ ! $ver ]]; then
      src+=$(pkg:get-version "$full")
    fi

    while read -r file; do
      mkdir -p "$(dirname ".bpan/$file")"

      n=${file//[^\/]/}
      n=${#n}
      prefix=..
      for (( i = 1; i < n; i++ )); do
        prefix+=/..
      done

      from=$BPAN_INSTALL/$file
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
    done < <(
      cd "$src" || exit
      find bin lib share -type f 2>/dev/null || true
    )

  done < <(
    ini:list |
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
    md2man < "$md" > "$temp"
    if +is-file-same "$man" "$temp"; then
      say -y "CURRENT '$man'"
    else
      mv "$temp" "$man"
      say -y "UPDATED '$man' from '$md'"
    fi
  done < <(
    ini:list --file=.bpan/config |
      grep '^update\.man'
  )
)
