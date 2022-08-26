upgrade:main() (
  cd "$BPAN_ROOT" || exit
  option_local=false

  if [[ $(git diff --stat) ]]; then
    error "Can't upgrade, '$BPAN_ROOT' git repo has uncommitted changes"
  fi

  repo=$(git config remote.origin.url) ||
    die "Can't determine bpan upstream repo"
  commit=$(git rev-parse HEAD) ||
    die "Can't determine bpan HEAD commit"
  branch=$(git rev-parse --abbrev-ref HEAD) ||
    die "Can't determine bpan branch"
  [[ $branch == main ]] ||
    error "'$BPAN_ROOT' must be on branch 'main' to 'bpan upgrade'"

  echo-y "Pulling '$repo' in '$BPAN_ROOT'..."

  git pull --quiet --ff-only origin "$branch" ||
    error "Could not git pull '$BPAN_ROOT'"

  if [[ $(git rev-parse HEAD) == "$commit" ]]; then
    echo-y "No upstream changes found"
  else
    echo-y "Pulled new changes to '$BPAN_ROOT'"
  fi

  echo-y "Updating BPAN index file..."
  rm -f "$index_file"
  source lib/index.bash

  echo-y "Updating packages used by BPAN:"
  source1 update
  update:main
)
