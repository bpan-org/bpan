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

install:usage() (
  echo "$app [<$app-opts>] $cmd [<cmd-opts>] <pkg-id...>"
)

install:options() (
  echo "U,unsafe      Install an unindexed package"
  echo "I,index       Refresh index file"
)

install:main() (
  [[ $# -gt 0 ]] ||
    error "'$app $cmd' requires one or more packages"

  source-once pkg

  pkg:index-update

  for id; do
    pkg:parse-id+ "$id"

    if [[ ! -d $src ]]; then
      mkdir -p "$(dirname "$src")"
      (
        say -y "Clone $repo -> $src"
        $option_verbose && set -x
        GIT_TERMINAL_PROMPT=0 git clone \
          --quiet \
          --depth 1 \
          --branch "$ver" \
          "$repo" "$src" 2>/dev/null
      ) || error "Can't 'git clone $repo'"
      if [[ $(git -C "$src" rev-parse HEAD) != "$commit" ]]; then
        rm -fr "$src"
        error "Bad commit: package '$full' version '$ver' commit '$commit'"
      fi
    fi

    (
      while read -r file; do
        rm -f "$BPAN_INSTALL/$file"

        n=${file//[^\/]/}; n=${#n}
        prefix=..
        for (( i = 1; i < n; i++ )); do prefix+=/..; done

        link=$BPAN_INSTALL/$file
        target=src/$owner/$name/$ver/$file
        if [[ ! -f $link ]] ||
           [[ $(readlink "$link") != $prefix/$target ]]
        then
          (
            say-y "Install $file -> $target"
            $option_verbose && set -x
            mkdir -p "$(dirname "$link")"
            ln -s "$prefix/$target" "$link"
          )
        fi
      done < <(
        cd "$src" || exit
        find bin lib man share -type f 2>/dev/null || true
      )
    )
  done
)
