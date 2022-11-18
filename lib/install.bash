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

install:main() (
  [[ $# -gt 0 ]] ||
    error "'$app $cmd' requires one or more packages"

  source-once util/pkg

  force_update=true pkg:index-update

  for id do
    pkg:parse-id+ "$id"

    base=${pkg_src%/*}
    if [[ -d $base ]]; then
      if [[ ! -d $pkg_src ]]; then
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
        say -y "Clone $pkg_repo -> $base"
        $option_verbose && set -x

        GIT_TERMINAL_PROMPT=0 git clone \
          --quiet \
          --no-checkout \
          "$pkg_repo" "$base" 2>/dev/null
      ) || error "Can't 'git clone $pkg_repo'"
    fi

    if [[ ! -d $pkg_src ]]; then
      # 'worktree --quiet' not available on git 2.8 (centos 6)
      git -C "$base" worktree add --force "$pkg_src" "$pkg_version" &>/dev/null ||
        error "Can't add git worktree for '$pkg_id=$pkg_version'"
      if [[ $(git -C "$pkg_src" rev-parse HEAD) != "$pkg_commit" ]]; then
        rm -fr "$pkg_src"
        error "Bad commit: package '$pkg_id' version '$pkg_version' commit '$pkg_commit'"
      fi
    fi

    (
      while read -r file; do
        rm -f "$BPAN_INSTALL/$file"

        n=${file//[^\/]/}; n=${#n}
        prefix=..
        for (( i = 1; i < n; i++ )); do prefix+=/..; done

        link=$BPAN_INSTALL/$file
        target=src/$pkg_host/$pkg_owner/$pkg_name/$pkg_version/$file
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
        cd "$pkg_src" || exit
        find bin lib man share -type f 2>/dev/null || true
      )
    )
  done
)
