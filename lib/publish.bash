# TODO redirect from https://bpan.org/publish-requests

publish:options() (cat <<...
I,index=    Index name to register to
c,check     Just run preflight checks. Don't publish
...
)

publish:main() (
  source-once util/db

  db:source:plugin publish

  publish:run "$@"
)

publish:run() (
  require_register=false

  publish:get-package-info

  publish:get-env

  publish:check

  $option_check && return

  publish:update-index-repo
)

publish:get-package-info() (
  die --stack
)

publish:get-env() (
  die --stack
)

publish:check() (
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

  if $require_register; then
    ini:list --file="$index_file_path" |
      grep -q "^package\.$package\." ||
        error \
          "Can't publish '$package'." \
          "Not yet registered. Try '$app register'."
  fi

  ini:get --file="$index_file_path" \
    package."$package".v"${version//./-}" >/dev/null &&
      error "$package version '$version' already published"

  say -y "Running tests"
  bpan-run test
  echo
)

publish:update-index-repo() (
  die --stack
)

publish:update-index() (
  ini:init "$index_file_path"

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

  author_name=$(
    git config -f .bpan/config \
      --get-regexp '^author\..*\.name$' |
      head -n1 |
      cut -d' ' -f2-
  )
  author_email=$(
    git config -f .bpan/config \
      --get-regexp '^author\..*\.email$' |
      head -n1 |
      cut -d' ' -f2-
  )
  export GIT_AUTHOR_NAME=$author_name
  export GIT_AUTHOR_EMAIL=$author_email
  export GIT_COMMITTER_NAME='BPAN GitHub Publisher'
  export GIT_COMMITTER_EMAIL='publish@bpan.org'

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

  cd ..

  git commit --all --message="${message//\'\'\'/\`\`\`}"

  git diff HEAD^

  git log -1

  git push
)
