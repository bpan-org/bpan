install:help() (
  cat <<'...'
Install BPAN Packages

# Synopsis

Some 'bpan install ...' commands:

```
$app install prelude-bash
$app install bpan-org/prelude-bash
$app install bpan-org/prelude-bash=0.1.0
$app install github:bpan-org/prelude-bash=0.1.0
```
...
)

install:getopt() {
  getopt_spec="\
$app [<$app-opts>] $command [<cmd-opts>] <pkg-id...>

'$app $command' Options:
--
U,unsafe      Install an unindexed package
I,index       Refresh index file

h,help        Get help for $command command
"
}

install:main() (
  [[ $# -gt 0 ]] ||
    error "'$app $command' requires one or more packages"

  source1 pkg

  pkg:get-index

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
      [[ $(git -C "$src" rev-parse HEAD) == "$commit" ]] || {
        rm -fr "$src"
        error "Bad commit: package '$full' version '$ver' commit '$commit'"
      }
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
            say-y "Installing $file -> $target"
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
