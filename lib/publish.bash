# TODO redirect from https://bpan.org/publish-requests

publish:options() (cat <<...
I,index=    Index name to register to
c,check     Just run preflight checks. Don't publish
...
)

publish:main() (
  if [[ ${GITHUB_ACTIONS-} == true ]]; then
    publish:gha-main "$@"
    return
  fi

  source-once util/db

  repo=$(ini:get package.repo) ||
    die --stack
  [[ $repo =~ https://github.com/([^/]+/[^/]+)$ ]] ||
    die --stack
  package_id=${BASH_REMATCH[1]}

  force_update=true db:sync

  db:find-package "$package_id"
  index_publish_url=$(ini:get "index.$index.publish") ||
    error "No config entry 'index.$index.publish'"

  publish:get-env

  publish:check-publish

  $option_check && return

  publish:trigger-publish
)

publish:get-env() {
  +git:in-repo ||
    error "Not in a git repo"

  [[ -f .bpan/config ]] ||
    error "Not in a $APP package repo"

  [[ $(ini:get package.name) != "$app" ]] ||
    error "Can't use '$app publish' for '$app'."

  token=$(ini:get host.github.token) ||
    error "No entry for 'host.github.token' in $root/config"
  if [[ $token != *????????????????????* ]]; then
    error "Missing or invalid host.github.token in $root/config"
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
          "Try '$app bump'."

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

  ini:list --file="$index_path" |
    grep -q "^package\.$package\." ||
      error \
        "Can't publish '$package'." \
        "Not yet registered. Try '$app register'."

  ini:get --file="$index_path" \
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

#### Requesting $APP Package Publish for [$package $version]\
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

**$APP Index Updater triggered and will begin processing this request soon…**
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
      "$index_publish_url" |
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
  index_file=index.ini

  set -x
  package_id=$gha_request_package
  package_version=$gha_request_version
  package_commit=$gha_request_commit
  package_sha512=$(
    cd package ||exit
    +git:commit-sha512 "$package_version"
  )
  comment_body=$(
    grep -v '^\*\*'"$APP"' Index Updater.*\*\*' \
      <<<"$gha_event_comment_body"
  )
  package_title=$(
    git config --file="package/.$app/config" \
      package.title
  )
  package_license=$(
    git config --file="package/.$app/config" \
      package.license
  )
  package_tag=$(
    git config --file="package/.$app/config" \
      package.tag
  )

  set "${BPAN_DEBUG_BASH_X:-+x}"
  comment_body+="

1. [Review Publish and Update Index]($gha_job_html_url)
"
  publish:gha-update-comment-body "$comment_body"
  $option_debug && set -x

  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    v=$(git config -f "$index_file" "package.$package_id.version")
    test_version=${v%.*}.$(( ${v##*.} + 1 ))
  fi
}

publish:gha-check-publish() {
  config=package/.bpan/config
  [[ -f $config ]] ||
    die "Package '$package_id' has no '.bpan/config' file"

  : "Check new version is greater than indexed one"
  indexed_version=$(
    git config -f "$index_file" "package.$package_id.version"
  )
  +source bashplus/version
  if [[ ${BPAN_INDEX_UPDATE_TESTING-} ]]; then
    +version:gt "$test_version" "$indexed_version" ||
      die "'$package_id' version '$package_version' "\
``````````"not greater than '$indexed_version'"
  else
    +version:gt "$package_version" "$indexed_version" ||
      die "'$package_id' version '$package_version' "\
''''''''''"not greater than '$indexed_version'"
  fi

  : "Check that requesting user is package author"
  author_host=$(ini:first --file="$config" '^author\..*\.host$') ||
    die "No author.*.host entry in '$package_id' config"
  author_user=$(ini:first --file="$config" '^author\..*\.user$') ||
    die "No author.*.user entry in '$package_id' config"
  package_author=$author_host:$author_user
  [[ $author_user == "$gha_triggering_actor" ]] ||
    die "Request from '$gha_triggering_actor' should be from '$author_user'"

  : "Check that request commit matches actual version commit"
  actual_commit=$(git -C package rev-parse "$package_version") || true
  [[ $actual_commit == "$package_commit" ]] ||
    die "'$package_commit' is not the actual commit "\
''''''''"for '$package_id' tag '$package_version'"

  : "Run the package's test suite"
  (cd package && bpan-run test -v) ||
    die "$package_id v$package_version failed tests"
}

publish:gha-update-index() (
  ini:init "$index_file"

  stamp=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%S')

  [[ ${#package_commit} -eq 40 ]] ||
    die "Can't get commit for '$package_id' v$package_version"

  # TODO Update all relevant fields

  ini:set "package.$package_id.title"   "$package_title"
  ini:set "package.$package_id.version" "$package_version"
  ini:set "package.$package_id.license" "$package_license"
  ini:set "package.$package_id.tag"     "$package_tag"
  ini:set "package.$package_id.author"  "$package_author"
  ini:set "package.$package_id.update"  "$stamp"
  ini:set "package.$package_id.commit"  "$package_commit"
  ini:set "package.$package_id.sha512"  "$package_sha512"

  # shellcheck disable=2153
  ini:set bpan.version "$VERSION"
  ini:set bpan.updated "$stamp"

  git config user.email "update-index@bpan.org"
  git config user.name "$APP Update Index"

  message="\
Publish $package_id=$package_version

    package=$package_id
    title=\"$package_title\"
    version=$package_version
    license=$package_license
    author=$package_author
    commit=$package_commit
    sha512=$package_sha512
"

  git commit --all --message="${message//\'\'\'/\`\`\`}"

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
        tail -n1 |
        cut -d+ -f2 |
        cut -d, -f1
    )
    line_num=$(( ${line_num:-0} + 1 ))

    publish_html_index_url=$(git config remote.origin.url)

    url=$publish_html_index_url/blob/$GITHUB_REF_NAME/index.ini#L$line_num
    comment_body+="\
1. [Publish Successful - \
Index Updated]($url)
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

  curl \
    --silent \
    --request POST \
    --header "Accept: application/vnd.github+json" \
    --header "$auth_header" \
    "$gha_event_comment_reactions_url" \
    --data "{\"content\":\"$thumb\"}" \
  >/dev/null || true

  if $ok; then
    say -g 'Publish Successful'
  else
    say -r 'Publish Failed'
  fi
)
