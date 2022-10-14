pkg:parse-id+() {
  commit=''

  local id=$1

  pkg:parse-id "$id"

  if [[ ! $ver ]]; then
    ver=$(pkg:get-version "$full")
  fi

  commit=$(pkg:get-commit "$full" "$ver")

  src=$BPAN_INSTALL/src/$domain/$owner/$name/$ver
}

pkg:parse-id() {
  name='' owner='' domain='' ver='' full='' src='' repo=''

  local id=$1
  local w='[-a-zA-Z0-9_]'
  local v='[-a-zA-Z0-9_.]'

  [[ $id =~ ^($w+:)?($w+/)?($w+)(=$v+)?$ ]] ||
    error "Invalid package id '$id'"

  domain=${BASH_REMATCH[1]:-github}
  domain=${domain%:}
  owner=${BASH_REMATCH[2]:-bpan-org}
  owner=${owner%/}
  name=${BASH_REMATCH[3]}
  ver=${BASH_REMATCH[4]:-''}
  ver=${ver#=}
  full=$domain:$owner/$name

  if [[ $domain == github ]]; then
    repo=https://github.com/$owner/$name
  else
    error "Invalid package domain '$domain'"
  fi

  src=$BPAN_INSTALL/src/$domain/$owner/$name/$ver
}

pkg:index-update() (
  if [[ ! -h $bpan_index_file ]]; then
    rm -f "$bpan_index_file"
    mkdir -p "$(dirname "$bpan_index_file")"
    ln -s \
      "$bpan_index_repo_dir/index.ini" \
      "$bpan_index_file"
  fi

  if [[ ! -f $bpan_index_file ]]; then
    git clone --quiet "$bpan_index_repo_url" "$BPAN_INSTALL/$bpan_index_repo_dir"
  fi

  if ${force_update:-false} ||
     [[ ${1-} == --force ]] ||
     [[ ! -f $bpan_index_file ]] ||
     [[ ! -h $bpan_index_file ]] ||
     pkg:index-too-old ||
     pkg:api-mismatch
  then
    [[ ${BPAN_TESTING-} ]] ||
      say+y "Updating BPAN package index..."
    git -C "$BPAN_INSTALL/$bpan_index_repo_dir" pull --quiet --ff-only origin main
  fi

  [[ -f $bpan_index_file ]] ||
    die "BPAN package index file not available"

  index_api_version=$(git config -f "$bpan_index_file" bpan.api-version || echo 0)

  if [[ $index_api_version -lt $BPAN_INDEX_API_VERSION ]]; then
    error "BPAN Index API Version mismatch. Try again later."
  elif [[ $index_api_version -gt $BPAN_INDEX_API_VERSION ]]; then
    error "BPAN version is too old for the index. Run: 'bpan upgrade'"
  fi
)

pkg:index-too-old() (
  head=$BPAN_INSTALL/$bpan_index_repo_dir/.git/FETCH_HEAD
  [[ -f $head ]] || return 0
  curr_time=$(+time)
  pull_time=$(+mtime "$head")
  (( curr_time - (bpan_index_life * 60) > pull_time ))
)

pkg:api-mismatch() {
  [[ $BPAN_INDEX_API_VERSION -gt \
    "$(git config -f "$bpan_index_file" bpan.api-version || echo 0)" \
  ]]
}

pkg:get-version() (
  full=$1
  git config -f "$bpan_index_file" "package.$full.version" ||
    error "No package '$full' found"
)

pkg:get-commit() (
  full=$1 version=$2
  git config -f "$bpan_index_file" "package.$full.v${version//./-}" ||
    error "Can't find commit for package '$full' version '$version'"
)

pkg:check-commit() (
  git config -f "$bpan_index_file" "package.$full.v${version//./-}" ||
    error "Can't find commit for package '$full' version '$version'"
)

pkg:installed() (
  shopt -s nullglob
  cd "$BPAN_INSTALL/src/" || exit 0
  printf '%s\n' */*/* |
    +sort |
    while IFS=/ read -r owner name ver; do
      echo "github:$owner/$name=$ver"
    done
)

pkg:is-primary() (
  id=$1
  pkg:parse-id "$id"
  find "$BPAN_INSTALL"/{lib,bin,share} -type l -print0 2>/dev/null |
    xargs -r -0 ls -l |
    grep -q "$owner/$name/$ver"
)
