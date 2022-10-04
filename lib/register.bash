register:main() (
  source-once pkg
  pkg:index-update --force

  say -y "Check Package is Ready to Register"
  register:preflight
  say -g "Package is Ready to Register"

  index_dir=.bpan/bpan-index
  rm -fr "$index_dir"

  say -y "\nPrepare BPAN Index Pull Request"
  register:update-bpan-index
  say -g "Pull Request is Prepared"

  say -y "\nSubmit BPAN Index Pull Request"
  pull_request_url=$(register:post-pull-request)
  say -g "Pull Request Submitted"

  say "\n${G}See:$Z $pull_request_url"

  rm -fr "$index_dir"
)

register:preflight() {
  token=$(config:get github.token) || true
  [[ $token =~ ^ghp_[a-zA-Z0-9]{36}$ ]] ||
    error "Your configured 'github.token' does not seem valid"
  o "GitHub token tooks ok"

  git:in-repo ||
    error "Not in a git repo directory"
  o "Inside a git repo directory"

  git:is-clean ||
    error "Git repo has uncommitted changes"
  o "Git repo is in a clean state"

  local config_file=.bpan/config
  [[ -f $config_file ]] ||
    error "Not in a bpan project directory"
  o "Inside a BPAN project directory"

  remote_url=$(git config remote.origin.url) ||
    error "No remote.origin.url found in .git/config"
  remote_url=${remote_url%.git}
  o "Remote url for project is '$remote_url'"

  if [[ $remote_url == git@github.com:*/* ]]; then
    remote_owner_repo=${remote_url#git@github.com:}
  elif [[ $remote_url == https://github.com/*/* ]]; then
    remote_owner_repo=${remote_url#https://github.com/}
  else
    error "'$remote_url' is not in a recognized format"
  fi
  package_full_name=github:$remote_owner_repo
  o "BPAN package full name is '$package_full_name'"
  package_owner=${remote_owner_repo%%/*}
  o "BPAN package owner is '$package_owner'"
  package_repo=${remote_owner_repo#*/}
  o "BPAN package repo is '$package_repo'"

  if grep -q '^\[package "'"$package_full_name"'"\]' "$bpan_index_file"; then
    error "Package '$package_full_name' is already registered"
  fi
  o "Package '$package_full_name' is not already registered"

  github_id=$(register:config owner.github) ||
    error "Config has no owner.github id field"
  o "GitHub user to update BPAN index is '$github_id'"

  package_name=$(register:config package.name) ||
    error "Config has no package.title"
  o "Config package.name = '$package_name'"

  package_title=$(register:config package.title) ||
    error "Config has no package.title"
  o "Config package.title = '$package_title'"

  package_version=$(register:config package.version) ||
    error "Config has no package.version"
  o "Config package.version = '$package_version'"

  author_name=$(register:config author.name) ||
    error "Config has no author.name"
  o "Config author.name = '$author_name'"

  [[ $package_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    error "Config package.version '$package_version' does not match '#.#.#'"
  [[ $package_version != 0.0.0 ]] ||
    error "Can't register package with version '0.0.0'"
  o "Package version '$package_version' looks ok"

  git:tag-exists "$package_version" ||
    error "No tag '$package_version' found"
  o "Git tag '$package_version' exists"

  commit=$(git:commit-sha "$package_version")
  [[ $commit == "$(git:commit-sha HEAD)" ]] ||
    error "Git tag '$package_version' commit is not HEAD commit"
  o "Git commit for tag '$package_version' is HEAD commit"

  git:tag-pushed "$package_version" ||
    error "Git tag '$package_version' not pushed"
  o "Git commit for tag '$package_version' is pushed to origin"

  # VERSION is correct
  # Changes is correct
  # License file looks right
  # Tests pass

  o "Running the test suite:"
  bpan test ||
    error "Test suite failed"
}

register:update-bpan-index() (
  local entry head line

  fork_repo_url=git@github.com:$github_id/bpan-index

  forked=false
  o "Cloning fork: '$fork_repo_url'"
  i=0
  while
    (( i++ < 10 )) &&
    ! git clone \
        --quiet \
        --branch=main \
        "$fork_repo_url" \
        "$index_dir" \
        2>/dev/null
  do
    mkdir -p "$index_dir"
    if ! $forked; then
      +post https://api.github.com/repos/bpan-org/bpan-index/forks >/dev/null
      o "Forked https://github.com/bpan-org/bpan-index"
      forked=true
    fi
    say -y "  * Waiting for fork to be ready to clone..."
    sleep 1
    rm -fr "$index_dir"
  done
  if (( i >= 10 )); then
    error "Failed to clone '$fork_repo_url'"
  fi
  o "Cloned '$fork_repo_url'"

  fork_branch=$package_owner/$package_name

  git -C "$index_dir" checkout --quiet -b "$fork_branch"
  o "Created branch '$fork_branch'"
  git -C "$index_dir" fetch --quiet "$bpan_index_repo_url" main
  o "Fetched main branch of '$bpan_index_repo_url'"
  git -C "$index_dir" reset --quiet --hard FETCH_HEAD
  o "Hard reset HEAD to '$bpan_index_repo_url' HEAD"

  entry=$(register:new-index-entry)
  head=$(head -n1 <<<"$entry")

  (
    cd "$index_dir" || exit
    (
      updated=false
      while read -r line; do
        if ! $updated && [[ $line == '[package'* && $head > "$line" ]]
        then
          echo "$entry"
          echo
          updated=true
        fi
        echo "$line"
      done < index.ini
      if ! $updated; then
        echo "$entry"
      fi
    ) > index
    mv index index.ini
  )

  git -C "$index_dir" commit --quiet --all \
    --message="Add $fork_branch $package_version"
  o "Committed the new index entry to the bpan-index fork"

  git -C "$index_dir" push --quiet --force origin "$fork_branch" &>/dev/null
  o "Pushed the new fork commit"
)

register:post-pull-request() (
  fork_branch=$package_owner/$package_name
  head=$github_id:$fork_branch
  base=main
  title="Register BPAN Package $package_full_name"
  body=$(+json-escape "\
Please add this new package to the \
[BPAN Index]($bpan_index_repo_url/blob/main/index.ini):

    name:    $package_name
    version: $package_version
    title:   $package_title
    author:  $author_name
    github:  $github_id"
  )

  json=$(cat <<...
{
  "head":  "$head",
  "base":  "$base",
  "title": "$title",
  "body":  "$body",
  "maintainer_can_modify": true
}
...
  )

  json=${json//$'\n'/\ }

  response=$(
    +post \
      https://api.github.com/repos/bpan-org/bpan-index/pulls \
      "$json"
  )

  pull_request_url=$(
    echo "$response" |
      grep '^  "html_url":' ||
      error "Unrecognized PR response:\n$(head <<<"$response")..."
  )

  echo "$pull_request_url" |
    head -n1 |
    cut -d'"' -f4
)

#------------------------------------------------------------------------------
+json-escape() (
  string=$1
  string=${string//$'\n'/\\n}
  string=${string//\"/\\\"}
  echo "$string"
)

+post() (
  url=$1
  data=${2-}
  cache=.bpan/bpan-index
  options=()
  if [[ $data ]]; then
    options+=(--data "$data")
  fi

  response=$(
    curl \
      --silent \
      --show-error \
      --request POST \
      --header "Accept: application/vnd.github+json" \
      --header "Authorization: Bearer $token" \
      --stderr "$cache/stderr" \
      --dump-header "$cache/header" \
      "${options[@]}" \
      "$url"
  )

  if grep -q '^  "errors":' <<<"$response"; then
    msg=$(grep '^      "message":' <<<"$response" || true)
    if [[ $msg ]]; then
      msg=$(
        echo "$msg" |
          head -n1 |
          cut -d'"' -f4
      )
    fi
    error "${msg:-"Unknown error for 'curl $url'"}"
  fi

  echo "$response"
)

o() (
  say -y "* $1"
)

register:config() (
  git config -f .bpan/config "$@"
)

register:new-index-entry() (
  entry=$(< "$root/share/template/index-entry.ini")
  while [[ $entry =~ \(%\ ([^%]*)\ %\) ]]; do
    prev=$entry
    expr=${BASH_REMATCH[1]%%\ }
    eval "value=$expr"
    entry=${entry/(% $expr %)/$value}
  done

  grep -v '^$' <<<"$entry"
)

register:tags-line() (
  if tags=$(register:config package.tags); then
    echo "tags = $tags"
  else
    echo 'tags ='
  fi
)

