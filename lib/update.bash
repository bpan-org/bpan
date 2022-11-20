update:options() (cat <<...
l,list    List possible template files
f,file=   Template file to update
t,type=   pkg | file | man | new | init | global
a,all     All types
I,index   Refresh index file
S,self    Update '$app' itself (to latest version)
...
)

update:main() (
  ini:init \
    "$root/etc/config" \
    "$root/config" \
    "$(pwd)/.bpan/config"

  if $option_self; then
    update:self

  elif ${option_list:-false}; then
    update:list

  else
    source-once util/pkg

    config=.bpan/config
    [[ -f $config ]] ||
      error "Can't 'bpan update'. No '$config' file."

    force_update=true pkg:index-update

    update:apply
  fi
)

update:apply() (
  source-once install

  update:packages
  update:templates
  update:manpages
)

update:list() (
  cd "$root/share/add" || exit
  find . -type l |
    +l:sort |
    cut -c3-
)

update:copy-file() (
  from=$1
  to=$2

  mkdir -p "$(dirname "$to")"

  if [[ -h $to ]] ||
     +fs:file-diff "$to" "$from"
  then
    (
      $option_verbose && set -x
      rm -f "$to"
      cp -Lp "$from" "$to"
    )
    say -y "UPDATED '$to' from '$from'"
  else
    say -y "CURRENT '$to'"
  fi
)

update:packages() (
  (
    file=lib/bpan.bash
    if [[ -f .bpan/$file ]] &&
      ! [[ -h .bpan/$file ]]
    then
      from=$root/$file
      to=.bpan/$file
      if +fs:file-same "$to" "$from"; then
        say -y "CURRENT '$to'"
      else
        (
          $option_verbose && set -x
          cp -Lp "$from" "$to"
        )
        say -y "UPDATED '$to'"
      fi
    fi
  )

  while read -r pkg; do
    pkg=${pkg#*=}

    pkg:parse-id+ "$pkg"

    if ! [[ -d $pkg_src ]]; then
      say -y "INSTALL $pkg_owner/$pkg_name $pkg_version"
      install:main "$pkg"
    fi

    if [[ $pkg_file ]]; then
      from=$BPAN_INSTALL/$pkg_file
      to=.bpan/$pkg_file

      update:copy-file "$from" "$to"
      continue
    fi

    option_index=false
    pkg:parse-id "$pkg"
    if [[ ! $pkg_version ]]; then
      pkg_src+=$(pkg:get-version "$pkg_id")
    fi

    while read -r file; do
      n=${file//[^\/]/}
      n=${#n}
      prefix=..
      for (( i = 1; i < n; i++ )); do
        prefix+=/..
      done

      from=$BPAN_INSTALL/$file
      to=.bpan/$file
      update:copy-file "$from" "$to"
    done < <(
      cd "$pkg_src" || exit
      find bin lib share -type f 2>/dev/null || true
    )

  done < <(
    ini:list |
      grep '^update\.package'
  )
)

update:templates() (
  source-once add
  name=$(ini:get package.name || echo 'no-name')
  while read -r line; do
    line=${line#file.bpan.}
    action=${line%%=*}
    file=${line#*=}

    if [[ $file == *\ * ]]; then
      IFS=' ' read -r to from <<<"$file"
    else
      from=$root/share/add/$file
      to=$file
    fi

    add:file-copy "$from" "$to"
  done < <(
    ini:list --file=.bpan/config |
      grep '^update\.file'
  )
)

update:manpages() (
  [[ -d doc ]] || return 0

  if ! +cmd:ok-ver pandoc 2.0.0; then
    say -r "Warning: Can't update man pages. Need 'pandoc'." >&2
    return
  fi

  if ! +sys:is-cmd md2man; then
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
    MD2MAN_DESC=$(ini:get package.title)
    MD2MAN_PROG="md2man v0.1.0"
    export MD2MAN_NUM MD2MAN_NAME MD2MAN_DESC MD2MAN_PROG

    +fs:mktemp
    md2man < "$md" > "$temp"
    if +fs:file-same "$man" "$temp"; then
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

update:self() (
  cd "$root" || exit

  +git:is-clean ||
    error \
      "Can't update '$app'" \
      "'$root' git repo has uncommitted changes"

  repo=$(git config remote.origin.url) ||
    die "Can't determine bpan upstream repo"
  commit=$(+git:commit-sha) ||
    die "Can't determine bpan HEAD commit"
  branch=$(+git:branch-name) ||
    die "Can't determine bpan branch"
  pkg_branch=$(ini:get package.branch) ||
    die "Can't find config entry 'package.branch'"
  [[ $branch == "$pkg_branch" ]] ||
    error "'$root' must be on branch '$pkg_branch' to '$app update --self'"

  say -y "Pulling '$repo' in '$root'..."

  (
    $option_verbose && set -x
    git fetch --quiet origin "$branch" ||
      error "Could not git fetch '$root'."
    git reset --hard --quiet FETCH_HEAD ||
      error "Could not git reset '$root'"
  )

  if [[ $(+git:commit-sha) == "$commit" ]]; then
    say -y "No upstream changes found"
  else
    say -y "Pulled new changes to '$root'"
  fi

  say -y "Updating BPAN index file..."
  source-once util/pkg
  pkg:index-update
)
