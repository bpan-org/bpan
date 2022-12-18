install:help() (
  cat <<'...'
Install BPAN Packages

# Synopsis

Some 'bpan install ...' commands:

```
$app install getopt-bash
$app install bpan-org/getopt-bash
$app install bpan-org/getopt-bash=0.1.0
$app install github:bpan-org/getopt-bash=0.1.0
```
...
)

install:default() (echo --help)

install:usage() (
  echo "$app [<$app-opts>] $cmd [<cmd-opts>] <pkg-id...>"
)

install:options() (cat <<...
U,update    Update index(es)
I,index=    Index name to install from

uninstall   Uninstall an installed package
...
)

install:main() (
  [[ $# -gt 0 ]] ||
    error "'$app $cmd' requires one or more packages"

  source-once db

  if ! $option_uninstall; then
    force_update=${option_update:-false} \
      db:sync
  fi

  for package_id; do
    if $option_uninstall; then
      uninstall:package "$package_id"
    else
      install:package "$package_id"
    fi
  done
)

install:package() (
  package_id=$1

  source-once db

  db:find-package "$package_id"

  pull_url=$(
    ini:vars owner name
    ini:get --file="$index_file_path" "host.$host.pull" ||
      error "Can't find index entry 'host.$host.pull'"
  )

  base=${source%/*}
  if [[ -d $base ]]; then
    if [[ ! -d $source ]]; then
      (
        say -y "Fetch $base"
        $option_verbose && set -x

        GIT_TERMINAL_PROMPT=0 git -C "$base" fetch \
          --quiet \
          2>/dev/null
      ) || error "Can't 'git -C $base fetch'"
    fi
  else
    mkdir -p "$(dirname "$base")"
    (
      say -y "Clone $pull_url -> $base"
      $option_verbose && set -x

      GIT_TERMINAL_PROMPT=0 git clone \
        --quiet \
        --no-checkout \
        "$pull_url" "$base" 2>/dev/null
    ) || error "Can't 'git clone $pull_url'"
  fi

  if [[ ! -d $source ]]; then
    # 'worktree --quiet' not available on git 2.8 (centos 6)
    git -C "$base" worktree add --force "$source" "$version" &>/dev/null ||
      error "Can't add git worktree for '$fqid=$version'"
    if [[ $(git -C "$source" rev-parse HEAD) != "$commit" ]]; then
      rm -fr "$source"
      error "Bad commit: package '$fqid' version '$version' commit '$commit'"
    fi
  fi

  (
    while read -r file; do
      rm -f "$install_dir/$file"

      n=${file//[^\/]/}; n=${#n}
      prefix=..
      for (( i = 1; i < n; i++ )); do prefix+=/..; done

      link=$install_dir/$file
      target=src/$host/$owner/$name/$version/$file
      if [[ ! -f $link ]] ||
          [[ $(readlink "$link") != $prefix/$target ]]
      then
        (
          say -y "Install $file -> $target"
          $option_verbose && set -x
          mkdir -p "$(dirname "$link")"
          ln -s "$prefix/$target" "$link"
        )
      fi
    done < <(
      cd "$source" || exit
      find bin lib man share -type f 2>/dev/null || true
    )
  )
)

uninstall:package() (
  package_id=$1

  db:find-package "$package_id"

  source=$host/$owner/$name/$version

  if ! [[ -d $install_dir/src/$source ]]; then
    say -r "'$fqid=$version' is not installed"
    return
  fi

  say -y "Uninstalling '$name':"

  cd "$install_dir" || exit

  while read -r line; do
    link=${line%% -> *}
    link=${link##* }
    file=${line##* -> }
    [[ $link ]] || continue
    file=${file##*../src/}
    say -w "- Unlink $link -> $file"
    unlink "$link"
  done <<< "$(
    find bin lib man share -type l -print0 2>/dev/null |
      xargs -r -0 ls -l |
      grep -F "$source"
  )"
  say -w "- Removing package src/$source/"
  rm -fr "src/$source/"

  while true; do
    # shellcheck disable=2046
    set -- $(find bin lib man share src -empty 2>/dev/null)
    [[ $# -gt 0 ]] || break
    rmdir "$@"
  done
)
