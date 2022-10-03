# TODO redirect from https://bpan.org/release-requests

release:options() (
  echo "c,check     Just run preflight checks. Don't release"
)

release:main() (
  if +in-gha; then
    release:gha-main "$@"
    return
  fi

  release:get-env

  release:check-release

  $option_check && return

  release:trigger-release
)

release:get-env() {
  git:in-repo ||
    error "Not in a git repo"

  [[ -f .bpan/config ]] ||
    error "Not in a BPAN package repo"

  token=$(config:get github.token) || true
  if [[ -z $token || $token == ___ ]]; then
    error "Missing or invalid github.token in $BPAN_ROOT/config"
  fi

  local url
  url=$(git config remote.origin.url) ||
    error "Can't find 'remote.origin.url' in .git/config"

  local regex='^git@github.com:(.+)/(.+)$'
  [[ $url =~ $regex ]] ||
    error "'$url' does not match '$regex'"

  user=${BASH_REMATCH[1]}
  repo=${BASH_REMATCH[2]}
  repo=${repo%.git}

  package=github:$user/$repo

  version=$(config:get package.version) ||
    error "Can't find 'package.version' in .bpan/config"

  commit=$(git:sha1 "$version")

  release_html_package_url=https://github.com/$user/$repo/tree/$version
}

release:check-release() (
  release_branch=$(config:get package.branch) || true
  release_branch=${release_branch:-main}

  [[ $(git:branch-name) == "$release_branch" ]] ||
    error "Not on release branch '$release_branch'"

  tag=$version
  git:tag-exists "$tag" ||
    error "Version '$version' is not a git tag"

  git:tag-pushed "$tag" ||
    error "Tag '$tag' is not pushed to origin"

  [[ $(git:sha1 "$tag") == $(git:sha1 HEAD) ]] ||
    error "Tag '$tag' is not HEAD commit"

  if [[ $package == github:bpan-org/bpan ]]; then
    error "Can't release '$package'. Not a package."
  fi

  say -y "Running tests"
  bpan test
  echo
)

release:trigger-release() (
  json="{\
\"package\":\"$package\",\
\"version\":\"$version\",\
\"commit\":\"$commit\"\
}"

  body="\
<!-- $json -->

#### Requesting BPAN Package Release for [$package $version]\
($release_html_package_url)
<details><summary>Details</summary>

* **Package**: $package
* **Version**: $version
* **Commit**:  $commit
* **Changes**:
$(
  read -r b a <<<"$(
    git config -f Changes --get-regexp '^version.*date' |
      head -n2 |
      cut -d. -f2-4 |
      xargs
  )"
  git log --pretty --format='%s' "$a".."$b"^ |
    xargs -I{} echo '  * {}'
)

</details>

**BPAN Index Updater triggered and will begin processing this request soon…**
"

  url=$(release:post-request "$body")

  say -g "Release for '$package' version '$version' requested"
  echo
  say -y "  $url"
)

release:post-request() (
  bpan_release_url=https://api.github.com/repos/bpan-org/bpan-index/issues/1/comments

  if [[ ${BPAN_INDEX_REPO_URL-} ]]; then
    [[ $BPAN_INDEX_REPO_URL == */github.com/* ]] ||
      error "'BPAN_INDEX_REPO_URL' must be a github repo url"
    url=${BPAN_INDEX_REPO_URL%/}
    url=${url/\/github.com\//\/api.github.com\/repos\/}
    url=$url/issues/1/comments
    bpan_release_url=$url
  fi

  body=$1
  body=${body//$'"'/\\'"'}
  body=${body//$'\n'/\\n}

  data=$(
    cat <<...
{
  "body":    "$body",
  "package": "$package",
  "version": "$version",
  "commit":  "$commit"
}
...
  )

  url=$(
    $option_verbose && set -x
    curl \
      --silent \
      --request POST \
      --header "Accept: application/vnd.github+json" \
      --header "Authorization: Bearer $token" \
      --data "$data" \
      "$bpan_release_url" |
    grep '"html_url"' |
    head -n1 |
    cut -d'"' -f4
  ) || true

  [[ $url ]] ||
    error "Release request failed"

  echo "$url"
)



#------------------------------------------------------------------------------
# GHA support
#------------------------------------------------------------------------------

release:gha-main() (
  ok=false

  +trap release:gha-post-status

  release:gha-get-env

  release:gha-check-release

  release:gha-update-index

  ok=true
)

release:gha-get-env() {
  bpan_index_file=index.ini

  set -x
  package=$gha_request_package
  version=$gha_request_version
  commit=$gha_request_commit
  comment_body=$(
    grep -v '^\*\*BPAN Index Updater.*\*\*' \
      <<<"$gha_event_comment_body"
  )

  set +x
  comment_body+="

1. [Review Release and Update Index]($gha_job_html_url)
"
  release:gha-update-comment-body "$comment_body"
  $option_debug && set -x

  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    v=$(git config -f "$bpan_index_file" "package.$package.version")
    test_version=${v%.*}.$(( ${v##*.} + 1 ))
  fi
}

release:gha-check-release() {
  config=package/.bpan/config
  [[ -f $config ]] ||
    die "Package '$package' has no '.bpan/config' file"

  : "Check new version is greater than indexed one"
  indexed_version=$(git config -f "$bpan_index_file" "package.$package.version")
  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    +version-gt "$test_version" "$indexed_version" ||
      die "'$package' version '$version' not greater than '$indexed_version'"
  else
    +version-gt "$version" "$indexed_version" ||
      die "'$package' version '$version' not greater than '$indexed_version'"
  fi

  : "Check that requesting user is package author"
  owner_github=$(config_file=$config config:get owner.github) ||
    die "No author.github entry in '$package' config"
  [[ $owner_github == "$gha_triggering_actor" ]] ||
    die "Request from '$triggering_actor' should be from '$owner_github'"

  : "Check that request commit matches actual version commit"
  actual_commit=$(git -C package rev-parse "$version") || true
  [[ $actual_commit == "$commit" ]] ||
    die "'$commit' is not the actual commit for '$package' tag '$version'"

  : "Run the package's test suite"
  (cd package && bpan test -v) ||
    die "$package v$version failed tests"
}

release:gha-update-index() (
  [[ ${#commit} -eq 40 ]] ||
    die "Can't get commit for '$package' v$version"

  # TODO Update all relevant fields

  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    git config -f "$bpan_index_file" \
      "package.$package.version" "$test_version"
    git config -f "$bpan_index_file" \
      "package.$package.v${test_version//./-}" "$commit"

  else
    git config -f "$bpan_index_file" \
      "package.$package.version" "$version"
    git config -f "$bpan_index_file" \
      "package.$package.v${version//./-}" "$commit"
  fi

  git config -f "$bpan_index_file" "package.$package.date" "$(date -u)"

  perl -pi -e 's/\t//' "$bpan_index_file"

  git config user.email "update-index@bpan.org"
  git config user.name "BPAN Update Index"

  git commit -a -m "Update $package=$version"

  git diff HEAD^

  git log -1

  git push
)

# Add the GHA job url to the request comment:
release:gha-update-comment-body() (
  $option_debug &&
    echo "+ release:gha-update-comment-body ..."

  content=$1
  content=${content//\"/\\\"}
  content=${content//$'\n'/\\n}

  auth_header=$(
    git config http.https://github.com/.extraheader
  )

  curl \
    --silent \
    --request PATCH \
    --header "Accept: application/vnd.github+json" \
    --header "$auth_header" \
    "$gha_event_comment_url" \
    --data "{\"body\":\"$content\"}" \
  >/dev/null
)


# React thumbs-up or thumbs-down on request comment:
release:gha-post-status() (
  [[ ${gha_event_comment_reactions_url} ]] || return

  set +x
  if $ok; then
    thumb='+1'

    line_num=$(
      git diff HEAD^ |
        grep '@' |
        head -n1 |
        cut -d+ -f2 |
        cut -d, -f1
    )
    line_num=$(( ${line_num:-0} + 1 ))

    release_html_index_url=$(git config remote.origin.url)

    comment_body+="\
1. [Release Successful - \
Index Updated]($release_html_index_url/blob/main/index.ini#L$line_num)
"
  else
    thumb='-1'
    comment_body+="\
1. [Release Failed - See Logs]($gha_job_html_url)
"
  fi

  release:gha-update-comment-body "$comment_body"
  $option_debug && set -x

  auth_header=$(
    git config http.https://github.com/.extraheader
  )

  rc=0
  curl \
    --silent \
    --request POST \
    --header "Accept: application/vnd.github+json" \
    --header "$auth_header" \
    "$gha_event_comment_reactions_url" \
    --data "{\"content\":\"$thumb\"}" \
  >/dev/null ||
    rc=$?

  if [[ $rc -eq 0 ]]; then
    say -g 'Release Successful'
  else
    say -r 'Release Failed'
  fi
)
