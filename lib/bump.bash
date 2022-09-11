bump:options() (
  echo "p,push   Push changes upstream"
)

bump:main() (
  [[ -d .git ]] ||
    error "'$app $cmd' require './.git/' directory"
  [[ $(git status -s) ]] &&
    error "Can't '$app $cmd' with uncommited changes"

  [[ -f Changes ]] ||
    error "'$app $cmd' require './Changes' file"
  [[ -f Meta ]] ||
    error "'$app $cmd' require './Meta' file"

  version1=$(bpan config -f Meta bpan.version)
  [[ $version1 ]] ||
    error "No 'bpan.version' found in '$config_file'"
  [[ $version1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    error "Unrecognized version '$version1'"
  git rev-parse "$version1" &>/dev/null ||
    die "No git tag found for version '$version1'"

  version2=${version1%.*}.$(( ${version1##*.} + 1))

  list=$(
    git log --pretty --format='%s' "$version1.." |
      while read -r line; do
        echo "done = $line"
      done
  )

  [[ $list ]] ||
    error "No changes commited since version '$version1'"

  if $option_push; then
    branch=$(git rev-parse --abbrev-ref HEAD)
    [[ $branch != HEAD ]] ||
      error "Can't push. Not checked out to a branch."
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

  changes=$(< Changes)

  (
    echo "$entry"
    echo
    echo "$changes"
  ) > Changes

  say -y "Updated 'Changes' file"

  bpan config -f Meta bpan.version "$version2"

  say -y "Updated 'Meta' file"

  git commit -q -a -m "Version $version2"

  commit=$(git rev-parse HEAD)
  say -y "Changes committed '${commit:0:8}'"

  git tag "$version2"
  say -y "Commit tagged as '$version2'"

  if $option_push; then
    git push -q --tag origin "$branch"
    say -y "Pushed to origin '$branch'"
  fi

  say -g "Version bump complete"

  echo

  say -y Commits:
  git log --pretty=oneline "$version1^..$version2"
)
