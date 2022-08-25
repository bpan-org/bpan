install:getopt() {
  getopt_spec="\
$app [<$app-opts>] $command <key> [<value>]

'$app $command' Options:
--
l,local       Symlink install to local repos

h,help        Get help for $command command
"
}

install:main() (
  export GIT_TERMINAL_PROMPT=0

  mkdir -p "$root"/local/{bin,lib,man/man{1,3},share,src,tmp}

  [[ $# -gt 0 ]] ||
    error "'$app $command' requires one or more packages"

  get-index-file

  for target; do
    install:parse-vars "$target"

    if ! $option_local; then
      mkdir -p "$(dirname "$src")"
      rm -fr "$src"
      (
        $option_verbose && set -x
        git clone \
          --quiet \
          --depth 1 \
          --branch "$ref" \
          "$repo" "$src" 2>/dev/null
      ) || error "Can't 'git clone $repo'"
      [[ $(git -C "$src" rev-parse HEAD) == "$commit" ]] || {
        rm -fr "$src"
        error "Bad commit: package '$full' version '$ref' commit '$commit'"
      }
    fi

    (
      cd "$src" || exit
      while read -r file; do
        rm -f "$root/local/$file"

        if $option_local; then
          (
            echo-y "Installing '$root/local/$file' (local)"
            $option_verbose && set -x
            ln -s "$src/$file" "$root/local/$file"
          )
        else
          n=${file//[^\/]/}; n=${#n}
          prefix=..
          for (( i = 1; i < n; i++ )); do prefix+=/..; done

          (
            echo-y "Installing '$root/local/$file'"
            $option_verbose && set -x
            ln -s "$prefix/src/$name/$ref/$file" "$root/local/$file"
          )
        fi
      done < <(
        find bin lib man share -type f 2>/dev/null || true
      )
    )
  done
)

install:parse-vars() {
  local target=$1
  local w='[-a-zA-Z0-9_]'
  local v='[-a-zA-Z0-9_.]'

  [[ $target =~ ^(github:)?($w+/)?($w+)(=$v+)?$ ]] ||
    error "Invalid install target '$target'"

  domain=${BASH_REMATCH[1]:-github}
  domain=${domain%:}
  owner=${BASH_REMATCH[2]:-bpan-org}
  owner=${owner%/}
  pkg=${BASH_REMATCH[3]}
  ref=${BASH_REMATCH[4]:-''}
  ref=${ref#=}
  name=$owner/$pkg
  full=$domain:$name

  if [[ -z $ref ]]; then
    ref=$(
      git config -f "$index_file" "pkg.$full.version"
    ) || error "No package '$full' found"
    ref=${ref#*=}
    commit=$(
      git config -f "$index_file" "pkg.$full.commit"
    ) || error "No 'commit' field in index for entry '$full'"
  fi

  if [[ $domain == github ]]; then
    repo=https://github.com/$name
  else
    error "Invalid package domain '$domain'"
  fi

  if $option_local; then
    name=${name##*/}
    src=$(cd "$root/.." && pwd -P)/$name
    [[ -d $src ]] ||
      error "No directory '$src'"
  else
    src=$root/local/src/$name/$ref
  fi
}
