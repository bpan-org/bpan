upgrade:options() (cat <<'...'
rebase    Upgrade using 'git pull --rebase'
...
)

upgrade:main() (
  cd "$root" || exit

  if git:is-dirty; then
    error "Can't upgrade, '$root' git repo has uncommitted changes"
  fi

  repo=$(git config remote.origin.url) ||
    die "Can't determine bpan upstream repo"
  commit=$(git rev-parse HEAD) ||
    die "Can't determine bpan HEAD commit"
  branch=$(git rev-parse --abbrev-ref HEAD) ||
    die "Can't determine bpan branch"
  [[ $branch == main ]] ||
    error "'$root' must be on branch 'main' to 'bpan upgrade'"

  say -y "Pulling '$repo' in '$root'..."

  opts=(--ff-only)
  $option_rebase && opts=(--rebase)

  (
    $option_verbose && set -x
    git pull --quiet "${opts[@]}" origin "$branch" ||
      error "Could not git pull '$root'." \
            "Try again with --rebase if you have local commits."
  )

  if [[ $(git rev-parse HEAD) == "$commit" ]]; then
    say -y "No upstream changes found"
  else
    say -y "Pulled new changes to '$root'"
  fi

  say-y "Updating BPAN index file..."
  source-once bpan/pkg
  pkg:index-update
)
