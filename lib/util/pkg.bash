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
  __pkg_main_index=${__pkg_main_index:-$(pkg:get-main-index)}

  pkg_name=''
  pkg_owner=''
  pkg_host=''
  pkg_version=''
  pkg_id=''
  pkg_src=''
  pkg_repo=''

  local id=$1
  local index=$__pkg_main_index    # TODO pass in value for multi index

  local w='[-a-zA-Z0-9_]'
  local v='[.0-9]'
  local ns='[^[:space:]]'

  [[ $id =~ ^($w+:)?($w+/)?($w+)(=$v+)?(:$ns+)?$ ]] ||
    error "Invalid package id '$id'"

  pkg_host=${BASH_REMATCH[1]:-$(ini:get "index.$index.host")} || true
  pkg_host=${pkg_host%:}
  pkg_owner=${BASH_REMATCH[2]:-$(ini:get "index.$index.owner")} || true
  pkg_owner=${pkg_owner%/}
  pkg_name=${BASH_REMATCH[3]}
  pkg_version=${BASH_REMATCH[4]}
  pkg_version=${pkg_version#=}
  pkg_file=${BASH_REMATCH[5]}
  if [[ $pkg_file ]]; then
    pkg_file=${pkg_file#:}
    pkg_file=${pkg_file/@/$pkg_name}
    if ! [[ $pkg_file =~ ^(bin|lib)/ ]]; then
      pkg_file=lib/$pkg_file
    fi
    if [[ $pkg_file == lib/* && $pkg_file != *.bash ]]; then
      pkg_file=$pkg_file.bash
    fi
  fi
  pkg_id=$pkg_host:$pkg_owner/$pkg_name

  pkg_repo=$(
    owner=$pkg_owner
    name=$pkg_name
    ini:vars owner name
    key=host.$pkg_host.source
    ini:get "$key" ||
      error "Can't find config value for '$key'"
  )

  pkg_src=$BPAN_INSTALL/src/$pkg_host/$pkg_owner/$pkg_name/$pkg_version
}

pkg:get-main-index() (
  local n=$'\n'
  [[ $(ini:list) =~ ${n}index\.([-a-z0-9]+)\.source= ]] ||
    error "No 'index.*.source' entry in $app config files"
  echo "${BASH_REMATCH[1]}"
)

pkg:config-vars() {
  __pkg_main_index=${__pkg_main_index:-$(pkg:get-main-index)}
  local index=$__pkg_main_index    # TODO pass in value for multi index
  local repo host

  bpan_index_source=$(ini:get "index.$index.source")
  bpan_index_branch=$(ini:get "index.$index.branch")

  host=$(ini:get "index.$index.host")
  repo=$(ini:get "index.$index.repo")

  bpan_index_dir=src/$host/$repo
  bpan_index_api_url=$(ini:get "index.$index.api")
  bpan_index_publish_url=$(ini:get "index.$index.publish")
  bpan_index_file=$(ini:get "index.$index.file")

  bpan_index_path=$BPAN_INSTALL/$bpan_index_dir/$bpan_index_file
}

pkg:index-update() (
  pkg:config-vars

  if [[ -f ${BPAN_TEST_INDEX_REPO-} ]]; then
    bpan_index_source=$BPAN_TEST_INDEX_REPO
    bpan_index_branch=${BPAN_TEST_INDEX_BRANCH:-main}
  fi

  if [[ ! -f $bpan_index_path ]]; then
    git clone \
      --quiet \
      --branch "$bpan_index_branch" \
      "$bpan_index_source" \
      "$BPAN_INSTALL/$bpan_index_dir"

  elif ! [[ ${BPAN_TEST_RUNNING-} ]]; then
    if ${force_update:-false} ||
      pkg:index-too-old ||
      pkg:api-mismatch
    then
      say -Y "Updating BPAN package index..."
      git -C "$BPAN_INSTALL/$bpan_index_dir" pull \
        --quiet \
        --ff-only \
        origin "$bpan_index_branch"
    fi
  fi

  [[ -f $bpan_index_path ]] ||
    die "BPAN package index file not available"

  index_api_version=$(
    git config -f "$bpan_index_path" bpan.api-version || echo 0
  )

  # XXX Compare bpan.VERSION with index.bpan.version
  # if [[ $index_api_version -lt $BPAN_INDEX_API_VERSION ]]; then
  #   error "BPAN Index API Version mismatch. Try again later."
  # elif [[ $index_api_version -gt $BPAN_INDEX_API_VERSION ]]; then
  #   error "BPAN version is too old for the index. Run: 'bpan upgrade'"
  # fi
)

pkg:index-too-old() (
  +source bashplus/time
  head=$BPAN_INSTALL/$bpan_index_dir/.git/FETCH_HEAD
  [[ -f $head ]] || return 0
  curr_time=$(+time:epoch)
  pull_time=$(+fs:mtime "$head")
  (( curr_time - (3 * 60) > pull_time ))
)

pkg:api-mismatch() {
  [[ $BPAN_INDEX_API_VERSION -gt \
    "$(git config -f "$bpan_index_path" bpan.api-version || echo 0)" \
  ]]
}

pkg:get-version() (
  pkg_id=$1
  git config -f "$bpan_index_path" "package.$pkg_id.version" ||
    error "No package '$pkg_id' found"
)

pkg:get-commit() (
  pkg_id=$1 version=$2
  index_version=$(
    git config \
      -f "$bpan_index_path" \
      "package.$pkg_id.version"
  ) || error "Can't find version for package '$pkg.id'"

  dir=$BPAN_INSTALL/$bpan_index_dir
  if [[ $index_version == "$version" ]]; then
    config=$(< "$bpan_index_path")
  else
    index_commit=$(
      git -C "$dir" log \
        -E --grep "(Publish|Register) $pkg_id=${version//./\\.}" \
        --pretty='%H'
    )
    [[ $index_commit ]] ||
      error "Can't find index commit for package '$pkg_id' version '$version'"
    config=$(git -C "$dir" show "$index_commit:index.ini") || die
  fi

  commit=$(
    git config -f- "package.$pkg_id.commit" <<< "$config" ||
    # XXX temporary support old/new index style
    git config -f- "package.$pkg_id.v${version//./-}" <<< "$config"
  ) ||
    error "Can't find commit for package '$pkg_id' version '$version'"

  echo "$commit"
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
