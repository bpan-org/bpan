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
U,update  Update index(es)
I,index=  Index name to install from
...
)

install:main() (
  [[ $# -gt 0 ]] ||
    error "'$app $cmd' requires one or more packages"

  source-once util/db

  force_update=${option_update:-false} \
    db:sync

  for package_id; do
    install:package "$package_id"
  done
)

install:package() (
  package_id=$1

  source-once util/db

  db:find-package "$package_id"

  repo=$(
    ini:vars owner name
    key=host.$host.source
    ini:get "$key" ||
      error "Can't find config value for '$key'"
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
      say -y "Clone $repo -> $base"
      $option_verbose && set -x

      GIT_TERMINAL_PROMPT=0 git clone \
        --quiet \
        --no-checkout \
        "$repo" "$base" 2>/dev/null
    ) || error "Can't 'git clone $repo'"
  fi

  if [[ ! -d $source ]]; then
    # 'worktree --quiet' not available on git 2.8 (centos 6)
    git -C "$base" worktree add --force "$source" "$latest" &>/dev/null ||
      error "Can't add git worktree for '$fqid=$latest'"
    if [[ $(git -C "$source" rev-parse HEAD) != "$commit" ]]; then
      rm -fr "$source"
      error "Bad commit: package '$id' version '$latest' commit '$commit'"
    fi
  fi

  (
    while read -r file; do
      rm -f "$install_dir/$file"

      n=${file//[^\/]/}; n=${#n}
      prefix=..
      for (( i = 1; i < n; i++ )); do prefix+=/..; done

      link=$install_dir/$file
      target=src/$host/$owner/$name/$latest/$file
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
