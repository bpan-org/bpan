bump:options() (
  echo "p,push      Push changes upstream"
)

bump:main() (
  +assert-perl

  if ${option_release:-false}; then
    option_push=true
  fi

  git:in-top-dir ||
    error "'$app $cmd' must be at repo toplevel"
  git:is-clean ||
    error "Can't '$app $cmd' with uncommited changes"

  [[ -f Changes ]] ||
    error "'$app $cmd' require './Changes' file"
  [[ -f Meta ]] ||
    error "'$app $cmd' require './Meta' file"

  version1=$(bpan config -f Meta package.version)
  [[ $version1 ]] ||
    error "No 'package.version' found in '$config_file'"
  [[ $version1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    error "Unrecognized version '$version1'"
  if [[ $version1 == 0.0.0 ]]; then
    rev_list=$(git rev-list HEAD | tail -n 1)
  else
    rev_list=$version1..
    git:has-ref "$version1" ||
      die "No git tag found for version '$version1'"
  fi

  if [[ $version1 == 0.0.0 ]]; then
    version2=0.1.0
  else
    version2=${version1%.*}.$(( ${version1##*.} + 1))
  fi

  git:tag-exists "$version2" &&
    error "Can't bump. Tag '$version2' already exists."

  list=$(
    git:subject-lines "$rev_list" |
      while read -r line; do
        echo "done = $line"
      done
  )

  grep -q -i '^done = wip\>' <<<"$list" &&
    error "Can't '$app $cmd' with WIP commits"

  if $option_push; then
    branch=$(git:branch-name)
    [[ $branch ]] ||
      error "Can't push. Not checked out to a branch."
    release_branch=$(config:get package.branch || echo main)
    [[ $branch == "$release_branch" ]] ||
      error "Can't push. Current branch is not '$release_branch'"
  fi

  if ! [[ $list ]]; then
    if $option_push; then
      bump:push
      return
    fi
    error "No changes commited since version '$version1'"
  fi

  say -y "Running 'bpan update'"
  bpan update

  say -y "Make sure 'bpan test' passes"
  bpan test

  say -y "Bumping to version '$version2'"

  entry="\
[version \"$version2\"]
date = $(date)
$list"

  if [[ $version1 == 0.0.0 ]]; then
    changes=''
  else
    changes=$(< Changes)
  fi

  (
    echo "$entry"
    if [[ $changes ]]; then
      echo
      echo "$changes"
    fi
  ) > Changes

  say -y "Updated 'Changes' file"

  bpan config -f Meta package.version "$version2"

  say -y "Updated 'Meta' file"

  for file in $(shopt -s nullglob; echo bin/* lib/*); do
    temp=$(+mktemp)
    perl -pe 's/^(\s*VERSION)=\d+\.\d+\.\d+(.*)/$1='"$version2"'$2/' \
      < "$file" > "$temp"
    if [[ -x $file ]]; then
      chmod '=rwx' "$temp"
    else
      chmod '=rw' "$temp"
    fi
    if +is-file-diff "$file" "$temp"; then
      mv "$temp" "$file"
      say -y "Updated VERSION=... in '$file'"
    fi
  done

  git commit -q -a -m "Version $version2"

  commit=$(git:commit-sha)
  say -y "Changes committed '${commit:0:8}'"

  git tag "$version2"
  say -y "Commit tagged as '$version2'"

  if $option_push; then
    bump:push
  fi

  say -g "Version bump complete"

  echo

  if [[ $version1 == 0.0.0 ]]; then
    revlist=''
  else
    rev_list="$version1^..$version2"
  fi

  say -y Commits:
  git log --pretty=oneline "$rev_list"
)

bump:push() (
  git push -q --tag origin "$branch"
  say -y "Pushed to origin '$branch'"

  # A temporary hack for ingydotnet only to update bpan-index after a
  # 'bpan bump -p'
  if ${option_release:-false}; then
    name=$(bpan config package.name) ||
      die "Can't get config value 'package.name'"
    [[ $name != bpan ]] ||
      error "Can't update index for 'bpan' itself"

    index_repo=~/src/+bpan/bpan-index

    echo
    say -y "Updating $name=$version2 in bpan-org/bpan-index index.ini"

    make -C "$index_repo" update NAME="$name"

    say -g "BPAN index updated"
  fi
)
