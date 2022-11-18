upgrade:options() (cat <<'...'
rebase    Upgrade using 'git pull --rebase'
...
)

upgrade:main() (
  cd "$root" || exit

  if +git:is-dirty; then
    error "Can't upgrade, '$root' git repo has uncommitted changes"
  fi

  repo=$(git config remote.origin.url) ||
    die "Can't determine bpan upstream repo"
  commit=$(+git:commit-sha) ||
    die "Can't determine bpan HEAD commit"
  branch=$(+git:branch-name) ||
    die "Can't determine bpan branch"
  pkg_branch=$(ini:get package.branch) ||
    die "Can't find config entry 'package.branch'"
  [[ $branch == "$pkg_branch" ]] ||
    error "'$root' must be on branch '$pkg_branch' to 'bpan upgrade'"

  say -y "Pulling '$repo' in '$root'..."

  opts=(--ff-only)
  $option_rebase && opts=(--rebase)

  (
    $option_verbose && set -x
    git pull --quiet "${opts[@]}" origin "$branch" ||
      error "Could not git pull '$root'." \
            "Try again with --rebase if you have local commits."
  )

  if [[ $(+git:commit-sha) == "$commit" ]]; then
    say -y "No upstream changes found"
  else
    say -y "Pulled new changes to '$root'"
  fi

  say -y "Updating BPAN index file..."
  source-once util/pkg
  pkg:index-update
)
