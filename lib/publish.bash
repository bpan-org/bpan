# TODO redirect from https://bpan.org/publish-requests

publish:options() (
  echo "c,check     Just run preflight checks. Don't publish"
)

publish:main() (
  if [[ ${GITHUB_ACTIONS-} == true ]]; then
    publish:gha-main "$@"
    return
  fi

  source-once util/pkg
  force_update=true pkg:index-update
  pkg:config-vars

  publish:get-env

  publish:check-publish

  $option_check && return

  publish:trigger-publish
)

publish:get-env() {
  +git:in-repo ||
    error "Not in a git repo"

  [[ -f .bpan/config ]] ||
    error "Not in a BPAN package repo"

  token=$(ini:get github.token) || true
  if [[ -z $token || $token == ___ ]]; then
    error "Missing or invalid github.token in $root/config"
  fi

  local url
  url=$(git config remote.origin.url) ||
    error "Can't find 'remote.origin.url' in .git/config" \
          "Did you forget to make an upstream repo for this package?"

  local regex='^git@github.com:(.+)/(.+)$'
  [[ $url =~ $regex ]] ||
    error "'$url' does not match '$regex'"

  user=${BASH_REMATCH[1]}
  repo=${BASH_REMATCH[2]}
  repo=${repo%.git}

  package=github:$user/$repo

  version=$(ini:get package.version) ||
    error "Can't find 'package.version' in .bpan/config"

  [[ $version != 0.0.0 ]] ||
    error "Can't publish version '0.0.0'." \
          "Try 'bpan bump'."

  commit=$(+git:sha1 "$version")

  publish_html_package_url=https://github.com/$user/$repo/tree/$version
}

publish:check-publish() (
  publish_branch=$(ini:get package.branch) || true
  publish_branch=${publish_branch:-main}

  [[ $(+git:branch-name) == "$publish_branch" ]] ||
    error "Not on publish branch '$publish_branch'"

  tag=$version
  +git:tag-exists "$tag" ||
    error "Version '$version' is not a git tag"

  +git:tag-pushed "$tag" ||
    error "Tag '$tag' is not pushed to origin"

  [[ $(+git:sha1 "$tag") == $(+git:sha1 HEAD) ]] ||
    error "Tag '$tag' is not HEAD commit"

  if [[ $package == github:bpan-org/bpan ]]; then
    error "Can't publish '$package'. Not a package."
  fi

  ini:list --file="$bpan_index_file" |
    grep -q "^package\.$package\." ||
      error \
        "Can't publish '$package'." \
        "Not yet registered. Try 'bpan register'."

  ini:get --file="$bpan_index_file" \
    package."$package".v"${version//./-}" >/dev/null &&
      error "$package version '$version' already published"

  say -y "Running tests"
  bpan-run test
  echo
)

publish:trigger-publish() (
  json="{\
\"package\":\"$package\",\
\"version\":\"$version\",\
\"commit\":\"$commit\"\
}"

  body="\
<!-- $json -->

#### Requesting BPAN Package Publish for [$package $version]\
($publish_html_package_url)
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

  url=$(publish:post-request "$body")

  say -g "Publish for '$package' version '$version' requested"
  echo
  say -y "  $url"
)

publish:post-request() (
  if +sys:is-cmd jq; then
    api_status=$(
      curl -s https://www.githubstatus.com/api/v2/summary.json |
        jq -r '.components | .[] | select(.name == "Actions") | .status'
    )

    if [[ $api_status != operational ]]; then
      error "\
  Can't publish. GitHub Actions is not operational.
  status='$api_status'.
  See: https://www.githubstatus.com/"
    fi
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
      "$bpan_index_publish_url" |
    grep '"html_url"' |
    head -n1 |
    cut -d'"' -f4
  ) || true

  [[ $url ]] ||
    error "Publish request failed"

  echo "$url"
)



#------------------------------------------------------------------------------
# GHA support
#------------------------------------------------------------------------------

publish:gha-main() (
  ok=false

  +trap publish:gha-post-status

  publish:gha-get-env

  publish:gha-check-publish

  publish:gha-update-index

  ok=true
)

publish:gha-get-env() {
  bpan_index_file=index.ini

  set -x
  package=$gha_request_package
  version=$gha_request_version
  commit=$gha_request_commit
  comment_body=$(
    grep -v '^\*\*BPAN Index Updater.*\*\*' \
      <<<"$gha_event_comment_body"
  )

  set "${BPAN_DEBUG_BASH_X:-+x}"
  comment_body+="

1. [Review Publish and Update Index]($gha_job_html_url)
"
  publish:gha-update-comment-body "$comment_body"
  $option_debug && set -x

  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    v=$(git config -f "$bpan_index_file" "package.$package.version")
    test_version=${v%.*}.$(( ${v##*.} + 1 ))
  fi
}

publish:gha-check-publish() {
  config=package/.bpan/config
  [[ -f $config ]] ||
    die "Package '$package' has no '.bpan/config' file"

  : "Check new version is greater than indexed one"
  indexed_version=$(
    git config -f "$bpan_index_file" "package.$package.version"
  )
  +source bashplus/version
  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    +version:gt "$test_version" "$indexed_version" ||
      die "'$package' version '$version' not greater than '$indexed_version'"
  else
    +version:gt "$version" "$indexed_version" ||
      die "'$package' version '$version' not greater than '$indexed_version'"
  fi

  : "Check that requesting user is package author"
  owner_github=$(ini:get --file="$config" owner.github) ||
    die "No author.github entry in '$package' config"
  [[ $owner_github == "$gha_triggering_actor" ]] ||
    die "Request from '$triggering_actor' should be from '$owner_github'"

  : "Check that request commit matches actual version commit"
  actual_commit=$(git -C package rev-parse "$version") || true
  [[ $actual_commit == "$commit" ]] ||
    die "'$commit' is not the actual commit for '$package' tag '$version'"

  : "Run the package's test suite"
  (cd package && bpan-run test -v) ||
    die "$package v$version failed tests"
}

publish:gha-update-index() (
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

  ini:set --file="$bpan_index_file" \
    "package.$package.date" "$(date -u)"

  git config user.email "update-index@bpan.org"
  git config user.name "BPAN Update Index"

  git commit -a -m "Publish $package=$version"

  git diff HEAD^

  git log -1

  git push
)

# Add the GHA job url to the request comment:
publish:gha-update-comment-body() (
  $option_debug &&
    echo "+ publish:gha-update-comment-body ..."

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
publish:gha-post-status() (
  [[ ${gha_event_comment_reactions_url} ]] || return

  set "${BPAN_DEBUG_BASH_X:-+x}"
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

    publish_html_index_url=$(git config remote.origin.url)

    comment_body+="\
1. [Publish Successful - \
Index Updated]($publish_html_index_url/blob/main/index.ini#L$line_num)
"
  else
    thumb='-1'
    comment_body+="\
1. [Publish Failed - See Logs]($gha_job_html_url)
"
  fi

  publish:gha-update-comment-body "$comment_body"
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
    say -g 'Publish Successful'
  else
    say -r 'Publish Failed'
  fi
)
