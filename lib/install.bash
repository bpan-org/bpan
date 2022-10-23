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

  source-once bpan/pkg

  force_update=true pkg:index-update

  for id do
    pkg:parse-id+ "$id"

    base=${src%/*}
    if [[ -d $base ]]; then
      if [[ ! -d $src ]]; then
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

    if [[ ! -d $src ]]; then
      git -C "$base" worktree add --force --quiet "$src" "$ver" ||
        error "Can't add git worktree for '$full=$var'"
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
        target=src/$domain/$owner/$name/$ver/$file
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
