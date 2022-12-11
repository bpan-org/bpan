update:options() (cat <<...
l,list    List possible template files
f,file=   Template file to update
t,type=   pkg | file | man | new | init | global
a,all     All types
S,self    Update '$app' itself (to latest version)
...
)

update:main() (
  ini:init \
    "$config_file_system" \
    "$config_file_global" \
    "$(pwd)/$config_file_local"

  if $option_self; then
    update:self

  elif ${option_list:-false}; then
    update:list

  else
    source-once util/db

    [[ -f $config_file_local ]] ||
      error "Can't 'bpan update'. No '$config_file_local' file."

    force_update=true
      db:sync

    update:apply
  fi
)

update:apply() (
  source-once install

  update:packages
  update:templates
  update:manpages

  ini:set --file="$config_file_local" bpan.version "$VERSION"
  ini:set --file="$config_file_local" bpan.updated "$bpan_run_timestamp"
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

  while read -r package_id; do
    package_id=${package_id#*=}

    db:find-package "$package_id"

    if ! [[ -d $source ]]; then
      say -y "INSTALL $host:$owner/$name=$latest"
      install:package "$package_id"
    fi

    if [[ $file ]]; then
      from=$install_dir/$file
      to=.bpan/$file

      update:copy-file "$from" "$to"
      continue
    fi

    while read -r file; do
      n=${file//[^\/]/}
      n=${#n}
      prefix=..
      for (( i = 1; i < n; i++ )); do
        prefix+=/..
      done

      from=$install_dir/$file
      to=.bpan/$file
      update:copy-file "$from" "$to"
    done < <(
      cd "$source" || exit
      find bin lib share -type f 2>/dev/null || true
    )

  done < <(
    ini:list --file="$config_file_local" |
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
    ini:list --file="$config_file_local" |
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
    option_uninstall=false \
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
    ini:list --file="$config_file_local" |
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
  if [[ ! ${BPAN_TEST_RUNNING-} ]]; then
    [[ $branch == main ]] ||
      error "'$root' must be on branch 'main' to '$app update --self'"
  fi

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
  source-once util/db
  db:sync
)
