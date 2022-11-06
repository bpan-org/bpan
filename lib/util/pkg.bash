pkg:parse-id+() {
  pkg_commit=''

  local id=$1

  pkg:parse-id "$id"

  if [[ ! $pkg_version ]]; then
    pkg_version=$(pkg:get-version "$pkg_id")
  fi

  pkg_commit=$(pkg:get-commit "$pkg_id" "$pkg_version")

  pkg_src=$BPAN_INSTALL/src/$pkg_host/$pkg_owner/$pkg_name/$pkg_version
}

pkg:parse-id() {
  pkg_name=''
  pkg_owner=''
  pkg_host=''
  pkg_version=''
  pkg_id=''
  pkg_src=''
  pkg_repo=''

  local id=$1
  local index=bpan    # TODO pass in value for multi index

  local w='[-a-zA-Z0-9_]'
  local v='[-a-zA-Z0-9_.]'

  [[ $id =~ ^($w+:)?($w+/)?($w+)(=$v+)?$ ]] ||
    error "Invalid package id '$id'"

  pkg_host=${BASH_REMATCH[1]:-$(ini:get "index.$index.host")} || true
  pkg_host=${pkg_host%:}
  pkg_owner=${BASH_REMATCH[2]:-$(ini:get "index.$index.owner")} || true
  pkg_owner=${pkg_owner%/}
  pkg_name=${BASH_REMATCH[3]}
  pkg_version=${BASH_REMATCH[4]:-''}
  pkg_version=${pkg_version#=}
  pkg_id=$pkg_host:$pkg_owner/$pkg_name

  if [[ $pkg_host == github ]]; then
    pkg_repo=https://github.com/$pkg_owner/$pkg_name
  else
    error "Invalid host '$pkg_host' for package '$pkg_id'"
  fi

  pkg_src=$BPAN_INSTALL/src/$pkg_host/$pkg_owner/$pkg_name/$pkg_version
}

pkg:config-vars() {
  local index=bpan    # TODO pass in value for multi index
  local repo

  bpan_index_clone_url=$(ini:get "index.$index.clone")
  bpan_index_branch=$(ini:get "index.$index.branch")

  local github_re='^https://github.com/([-a-zA-Z0-9]+/[-a-zA-Z0-9]+)$'
  if [[ $bpan_index_clone_url =~ $github_re ]]; then
    repo=${BASH_REMATCH[1]}
    bpan_index_repo_dir=src/github/$repo
    bpan_index_api_url=$(ini:get index.$index.api)
    bpan_index_publish_url=$(ini:get index.$index.publish)
  else
    error "Invalid config value 'index.$index.clone'='$bpan_index_clone_url'"
  fi

  bpan_index_file=$BPAN_INSTALL/$bpan_index_repo_dir/index.ini
}

pkg:index-update() (
  pkg:config-vars

  if [[ -f ${BPAN_TEST_INDEX_REPO-} ]]; then
    bpan_index_clone_url=$BPAN_TEST_INDEX_REPO
    bpan_index_branch=main
  fi

  if [[ ! -f $bpan_index_file ]]; then
    git clone \
      --quiet \
      --branch "$bpan_index_branch" \
      "$bpan_index_clone_url" \
      "$BPAN_INSTALL/$bpan_index_repo_dir"

  elif ! [[ ${BPAN_TEST_RUNNING-} ]]; then
    if ${force_update:-false} ||
      pkg:index-too-old ||
      pkg:api-mismatch
    then
      say -Y "Updating BPAN package index..."
      git -C "$BPAN_INSTALL/$bpan_index_repo_dir" pull \
        --quiet \
        --ff-only \
        origin main
    fi
  fi

  [[ -f $bpan_index_file ]] ||
    die "BPAN package index file not available"

  index_api_version=$(
    git config -f "$bpan_index_file" bpan.api-version || echo 0
  )

  if [[ $index_api_version -lt $BPAN_INDEX_API_VERSION ]]; then
    error "BPAN Index API Version mismatch. Try again later."
  elif [[ $index_api_version -gt $BPAN_INDEX_API_VERSION ]]; then
    error "BPAN version is too old for the index. Run: 'bpan upgrade'"
  fi
)

pkg:index-too-old() (
  +source bashplus/time
  head=$BPAN_INSTALL/$bpan_index_repo_dir/.git/FETCH_HEAD
  [[ -f $head ]] || return 0
  curr_time=$(+time:epoch)
  pull_time=$(+fs:mtime "$head")
  (( curr_time - (3 * 60) > pull_time ))
)

pkg:api-mismatch() {
  [[ $BPAN_INDEX_API_VERSION -gt \
    "$(git config -f "$bpan_index_file" bpan.api-version || echo 0)" \
  ]]
}

pkg:get-version() (
  pkg_id=$1
  git config -f "$bpan_index_file" "package.$pkg_id.version" ||
    error "No package '$pkg_id' found"
)

pkg:get-commit() (
  pkg_id=$1 version=$2
  git config -f "$bpan_index_file" "package.$pkg_id.v${version//./-}" ||
    error "Can't find commit for package '$pkg_id' version '$version'"
)

pkg:installed() (
  shopt -s nullglob
  cd "$BPAN_INSTALL/src/" || exit 0
  printf '%s\n' */*/* |
    +l:sort |
    while IFS=/ read -r owner name ver; do
      echo "github:$owner/$name=$ver"
    done
)

pkg:is-primary() (
  id=$1
  pkg:parse-id "$id"
  find "$BPAN_INSTALL"/{lib,bin,share} -type l -print0 2>/dev/null |
    xargs -r -0 ls -l |
    grep -q "$pkg_owner/$pkg_name/$pkg_version"
)
