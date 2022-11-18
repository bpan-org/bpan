register:main() (
  source-once util/pkg
  force_update=true pkg:index-update
  pkg:config-vars

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
  token=$(ini:get host.github.token) ||
    error "No entry for 'host.github.token' in $root/config"
  [[ $token =~ [a-zA-Z0-9]{36} ]] ||
    error "Your configured 'host.github.token' does not seem valid"
  o "GitHub token looks ok"

  +git:in-repo ||
    error "Not in a git repo directory"
  o "Inside a git repo directory"

  +git:is-clean ||
    error "Git repo has uncommitted changes"
  o "Git repo is in a clean state"

  [[ -f .bpan/config ]] ||
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
  package_id=github:$remote_owner_repo
  o "BPAN package full name is '$package_id'"
  package_owner=${remote_owner_repo%%/*}
  o "BPAN package owner is '$package_owner'"
  package_repo=${remote_owner_repo#*/}
  o "BPAN package repo is '$package_repo'"

  if grep -q '^\[package "'"$package_id"'"\]' "$bpan_index_path"; then
    error "Package '$package_id' is already registered"
  fi
  o "Package '$package_id' is not already registered"

  author_host=$(ini:first '^author\..*\.host$') ||
    error "No author.*.host entry in config"
  author_user=$(ini:first '^author\..*\.user$') ||
    error "No author.*.user entry in config"
  package_author=$author_host:$author_user
  [[ $package_author == github:* ]] ||
    error "Config package.author should be 'github:<username>'"
  github_id=$author_user
  : "$(register:config "author.$package_author.name")" ||
    error "Config has no '[author \"$package_author\"]' section"
  o "User to update BPAN index is '$package_author'"

  package_name=$(register:config package.name) ||
    error "Config has no package.title"
  o "Config package.name = '$package_name'"

  package_title=$(register:config package.title) ||
    error "Config has no package.title"
  [[ $package_title != *CHANGEME* ]] ||
    error "Please change the 'package.title' entry in '.bpan/config'"
  o "Config package.title = '$package_title'"

  package_version=$(register:config package.version) ||
    error "Config has no package.version"
  o "Config package.version = '$package_version'"

  package_license=$(register:config package.license) ||
    error "Config has no package.license"
  o "Config package.license = '$package_license'"

  package_tag=$(register:config package.tag) ||
    error "Config has no package.tag"
  o "Config package.tag = '$package_tag'"

  [[ $package_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    error "Config package.version '$package_version' does not match '#.#.#'"
  [[ $package_version != 0.0.0 ]] ||
    error "Can't register package with version '0.0.0'." \
          "Try 'bpan bump'."
  o "Package version '$package_version' looks ok"

  +git:tag-exists "$package_version" ||
    error "No tag '$package_version' found"
  o "Git tag '$package_version' exists"

  package_commit=$(+git:commit-sha "$package_version")
  [[ $package_commit == "$(+git:commit-sha HEAD)" ]] ||
    error "Git tag '$package_version' commit is not HEAD commit"
  o "Git commit for tag '$package_version' is HEAD commit"

  +git:tag-pushed "$package_version" ||
    error "Git tag '$package_version' not pushed"
  o "Git commit for tag '$package_version' is pushed to origin"

  # VERSION is correct
  # Changes is correct
  # License file looks right
  # Tests pass

  o "Running the test suite:"
  bpan-run test ||
    error "Test suite failed"

  package_update=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%S')
  package_sha512=$(+git:commit-sha512 "$package_version")
}

register:update-bpan-index() (
  local entry head line

  fork_repo_url=git@github.com:$github_id/${bpan_index_api_url##*/}

  forked=false
  o "Cloning fork: '$fork_repo_url'"
  i=0
  while
    (( i++ < 10 )) &&
    ! git clone \
        --quiet \
        "$fork_repo_url" \
        "$index_dir" \
        2>/dev/null
  do
    mkdir -p "$index_dir"
    if ! $forked; then
      +post "$bpan_index_api_url/forks" >/dev/null
      o "Forked $bpan_index_source"
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
  git -C "$index_dir" fetch --quiet \
    "$bpan_index_source" \
    "$bpan_index_branch"
  o "Fetched '$bpan_index_branch' branch of '$bpan_index_source'"
  git -C "$index_dir" reset --quiet --hard FETCH_HEAD
  o "Hard reset HEAD to '$bpan_index_source' HEAD"

  entry=$(register:new-index-entry)
  head=$(head -n1 <<<"$entry")

  (
    cd "$index_dir" || exit
    (
      updated=false
      while read -r line; do
        if ! $updated && [[ $line == '[package'* && $head < "$line" ]]
        then
          echo "$entry"
          echo
          updated=true
        fi
        echo "$line"
      done < "$bpan_index_file"
      if ! $updated; then
        echo
        echo "$entry"
      fi
    ) > index
    mv index "$bpan_index_file"

    ini:set --file="$bpan_index_file" bpan.version "$VERSION"
    ini:set --file="$bpan_index_file" bpan.updated "$package_update"
  )

  message="\
Register $package_id=$package_version

    package=$package_id
    title=\"$package_title\"
    version=$package_version
    license=$package_license
    author=$package_author
    commit=$package_commit
    sha512=$package_sha512
"

  git -C "$index_dir" commit --quiet --all \
    --message="${message//\'\'\'/\`\`\`}"
  o "Committed the new index entry to the bpan-index fork"

  git -C "$index_dir" push --quiet --force origin "$fork_branch" &>/dev/null
  o "Pushed the new fork commit"
)

register:post-pull-request() (
  fork_branch=$package_owner/$package_name
  head=$github_id:$fork_branch
  base=$bpan_index_branch
  title="Register $package_id=$package_version"
  http=https://github.com/$remote_owner_repo/tree/$package_version
  body=$(+json-escape "\
Please add this new package to the \
[BPAN Index]($bpan_index_source/blob/$bpan_index_branch/$bpan_index_file):

> $http

    package: $package_id
    title:   $package_title
    version: $package_version
    license: $package_license
    author:  $package_author"
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
      "$bpan_index_api_url/pulls" \
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

  if grep -q '^ \+"errors":' <<<"$response"; then
    msg=$(grep '^ \+"message":' <<<"$response" || true)
    if [[ $msg ]]; then
      msg=$(
        echo "$msg" |
          head -n1 |
          cut -d'"' -f4
      )
    fi
    error "${msg:-"Unknown error for 'curl $url'"}" "$response"
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
  package_version_key=${package_version//./-}
  entry=$(< "$root/share/template/index-entry.ini")
  while [[ $entry =~ \(%\ ([^%]*)\ %\) ]]; do
    prev=$entry
    expr=${BASH_REMATCH[1]%%\ }
    eval "value=$expr"
    entry=${entry/(% $expr %)/$value}
  done

  grep -v '^$' <<<"$entry"
)
