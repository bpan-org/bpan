pkg:parse-id+() {
  commit=''

  local id=$1

  pkg:parse-id "$id"

  if [[ ! $ver ]]; then
    ver=$(pkg:get-version "$full")
  fi

  commit=$(pkg:get-commit "$full" "$ver")

  src=$BPAN_INSTALL/src/$owner/$name/$ver
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

  if ${option_local:-false}; then
    src=$local_root/$name
    [[ -d $src ]] ||
      error "No directory '$src'"
  else
    src=$BPAN_INSTALL/src/$owner/$name/$ver
  fi
}

pkg:get-index() (
  if ${option_index:-false} ||
     [[ ! -f $index_file ]] ||
     [[ $(find "$index_file" -mmin +60) ]] ||
     [[ $BPAN_INDEX_API_VERSION -gt \
        "$(git config -f "$index_file" bpan.api-version || echo 0)" \
     ]]
  then
    [[ ${BPAN_TESTING-} ]] ||
      say+y "Updating BPAN package index..."
    mkdir -p "$root/local"
    curl --fail -s "$index_url" > "$index_file" ||
      rm -f "$index_file"
  fi

  [[ -f $index_file ]] ||
    die "BPAN package index file not available"

  index_api_version=$(git config -f "$index_file" bpan.api-version || echo 0)

  if [[ $index_api_version -lt $BPAN_INDEX_API_VERSION ]]; then
    error "BPAN Index API Version mismatch. Try again later."
  elif [[ $index_api_version -gt $BPAN_INDEX_API_VERSION ]]; then
    error "BPAN version is too old for the index. Run: 'bpan upgrade'"
  fi
)

pkg:get-version() (
  full=$1
  git config -f "$index_file" "pkg.$full.version" ||
    error "No package '$full' found"
)

pkg:get-commit() (
  full=$1 version=$2
  git config -f "$index_file" "pkg.$full.v${version//./-}" ||
    error "Can't find commit for pkg '$full' version '$version'"
)

pkg:check-commit() (
  git config -f "$index_file" "pkg.$full.v${version//./-}" ||
    error "Can't find commit for pkg '$full' version '$version'"
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
