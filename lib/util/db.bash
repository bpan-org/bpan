w='[-a-zA-Z0-9_]'
ns='[^[:space:]]'

readonly package_id_pattern="^($w+:)?($w+/)?($w+)(=[.0-9]+)?(:$ns+)?$"

db:index-names() (
  if
    IFS=',' read -r -a names <<<"$(ini:get index.order)" &&
    [[ ${#names[*]} -gt 0 ]]
  then
    printf '%s\n' "${names[@]}"

  elif [[ ${option_count_index:-0} -gt 0 ]]; then
    for name in "${option_index[@]}"; do
      ini:get "index.$name.source" >/dev/null ||
        error "Invalid $APP index name: '$name'"
      echo "$name"
    done

  else
    ini:list |
      grep -E '^index\..*\.source=' |
      cut -d'=' -f1 |
      cut -d'.' -f2- |
      rev |
      cut -d'.' -f2- |
      rev
  fi
)

db:sync() (
  while read -r index_name; do
    db:get-index-info "$index_name"

    if [[ ! -f $index_file_path ]]; then
      git clone \
        --quiet \
        --branch "$index_branch" \
        "$index_from" \
        "$index_file_dir"

    elif ! [[ ${BPAN_TEST_RUNNING-} ]]; then
      if ${force_update:-false} ||
        db:index-too-old
      then
        say -Y "Updating $APP package index '$index_name'"
        git -C "$index_file_dir" pull \
          --quiet \
          --ff-only \
          origin "$index_branch"
      fi
    fi

    [[ -f $index_file_path ]] ||
      die "$APP '$index_name' index file not available"

  done <<<"$(db:index-names)"
)

db:sync-plugins() (
  base=$install_dir/plugin
  mkdir -p "$base"
  read -r -a plugins <<<"$(
    git config --file="$index_file_path" --get-regexp ^plugin |
      cut -d. -f2 |
      sort |
      uniq
  )"
  for plugin in "${plugins[@]}"; do
    source=$(git config --file="$index_file_path" plugin."$plugin".source)
    dir=${source##*/}
    if ! [[ -d $base/$dir ]]; then
      git clone --quiet "$source" "$base/$dir"
    elif ${option_update:-false} || ${force_update:-false}; then
      git -C "$base/$dir" pull --quiet --ff-only
    fi
  done
)

db:source:plugin() {
  local plugin_type=$1
  local library_key=${2:-$plugin_type}

  db:sync

  index=${index:-$(db:get-package-index)}

  db:get-index-info "$index"

  db:sync-plugins "$index"

  plugin_name=$(
    git config --file="$index_file_path" \
      "plugin.$plugin_type.source"
  ) || return 0
  plugin_name=${plugin_name##*/}

  local library_path
  library_path=$(
    git config --file="$index_file_path" \
      "plugin.$plugin_type.$library_key"
  ) ||
    error "Can't find plugin '$plugin_type' key '$library_key'"

  source "$install_dir/plugin/$plugin_name/$library_path"
}

db:get-package-index() (
  owner=$(ini:get package.owner) ||
    error "Can't find 'package.owner' in config"
  name=$(ini:get package.name) ||
    error "Can't find 'package.name' in config"
  package_id=$owner/$name
  db:find-package "$package_id"
  echo "$index"
)

db:get-index-info() {
  local index_name=$1

  index_from=$(ini:get "index.$index_name.source")
  index_branch=$(ini:get "index.$index_name.branch" || echo main)

  local path
  path=$(ini:get "index.$index_name.path" || true)
  if ! [[ $path ]]; then
    if [[ $index_from == https://github.com/* ]]; then
      path=github/${index_from#https://github.com/}/index.ini
    else
      error "Can't determine config value for 'index.$index_name.path'"
    fi
  fi

  index_file_path=$install_dir/src/$path
  index_file_name=${index_file_path##*/}
  index_file_dir=${index_file_path%/*}
}

db:get-index-config() {
  local index_name=$1
  index_default_host=$(ini:get "index.$index_name.host")
  index_default_owner=$(ini:get "index.$index_name.owner")
}

db:find-packages() (
  pattern=$1
  option_quiet=true

  while read -r index; do
    db:get-index-info "$index"
    cat "$index_file_path" |
      git config -f- --get-regexp '^package\..*\.title$' |
      cut -d. -f2- |
      tr / '\t' |
      tr ' ' . |
      cut -d. -f 1,3- |
      tr -d \''()' |
      grep -i -E $'^.*\t.*'"$pattern" |
      tr '\t' / |
      cut -d. -f1 |
#       tee /dev/stderr |
      +l:sort |
      uniq || true
  done <<<"$(db:index-names)"
)

db:find-package() {
  local package_id=$1

  local found=()
  while read -r index; do
    if db:index-has-package "$index" "$package_id"; then
      db:get-package-release-info "$index" "$package_id"
      found+=("$index:$fqid")
    fi
  done <<<"$(db:index-names)"

  case "${#found[*]}" in
    1)
      index=${found[0]%%:*}
      return
      ;;
    0) error "No package '$package_id' found" ;;
    *) error "More than one package '$package_id' found:" \
             "${found[@]/:/ - }"
       ;;
  esac
}

db:index-has-package() (
  index=$1 package_id=$2
  db:get-index-info "$index"
  db:package-parse-id "$package_id" "$index"
  latest=$(ini:get --file="$index_file_path" "package.$fqid.version") ||
    return
  +source bashplus/version
  +version:ge "$latest" "$version"
)

db:get-package-release-info() {
  local index=$1 package_id=$2
  db:get-index-info "$index"
  db:package-parse-id "$package_id" "$index"
  latest=$(ini:get --file="$index_file_path" "package.$fqid.version")
  if [[ ! $version || $version == "$latest" ]]; then
    version=$(ini:get --file="$index_file_path" "package.$fqid.version")
    commit=$(ini:get --file="$index_file_path" "package.$fqid.commit")
    sha512=$(ini:get --file="$index_file_path" "package.$fqid.sha512")
    source=$install_dir/src/$host/$owner/$name/$latest
  else
    db:get-package-version-info "$package_id" "$version"
  fi
}

db:get-package-version-info() {
  local package_id=$1 version=$2
  local index_version
  index_version=$(
    git config \
      -f "$index_file_path" \
      "package.$fqid.version"
  ) || error "Can't find version for package '$package_id'"

  local config
  if [[ $index_version == "$version" ]]; then
    config=$(< "$index_file_path")
  else
    local index_commit
    index_commit=$(
      git -C "$index_file_dir" log \
        -E --grep "(Publish|Register) $fqid=${version//./\\.}" \
        --pretty='%H'
    )
    [[ $index_commit ]] ||
      error "Can't find index commit for package '$package_id' version '$version'"
    config=$(git -C "$index_file_dir" show "$index_commit:index.ini") || die
  fi

  commit=$(
    git config -f- "package.$fqid.commit" <<< "$config"
  ) ||
    error "Can't find commit for package '$package_id' version '$version'"
  sha512=$(
    git config -f- "package.$fqid.sha512" <<< "$config"
  ) ||
    error "Can't find sha512 for package '$package_id' version '$version'"
  source=$install_dir/src/$host/$owner/$name/$version
}

db:package-parse-id() {
  local package_id=$1 index=$2

  [[ $package_id =~ $package_id_pattern ]] ||
    error "Invalid package id '$package_id'"

  host=${BASH_REMATCH[1]:-$(ini:get --file="$index_file_path" "default.host")}
  host=${host%:}
  owner=${BASH_REMATCH[2]:-$(ini:get --file="$index_file_path" "default.owner")}
  owner=${owner%/}
  name=${BASH_REMATCH[3]}
  fqid=$host:$owner/$name
  version=${BASH_REMATCH[4]-}
  version=${version#=}
  file=${BASH_REMATCH[5]-}
  if [[ $file ]]; then
    file=${file#:}
    file=${file/@/$name}
    if ! [[ $file =~ ^(bin|lib)/ ]]; then
      file=lib/$file
    fi
    if [[ $file == lib/* && $file != *.bash ]]; then
      file=$file.bash
    fi
  fi
}

db:list-installed() (
  shopt -s nullglob
  cd "$install_dir/src/" || exit 0
  printf '%s\n' */*/*/[0-9]* |
    +l:sort |
    while IFS=/ read -r host owner name ver; do
      echo "$host:$owner/$name=$ver"
    done
)

db:get-version() (
  fqid=$1
  git config -f "$index_file_path" "package.$fqid.version" ||
    error "No package '$fqid' found"
)

db:package-is-primary() (
  id=$1
  while read -r index; do
    db:get-index-info "$index"
    db:package-parse-id "$id" "$index"

    (
      find "$install_dir"/{lib,bin,share} \
        -type l \
        -print0 \
        2>/dev/null || true
    ) |
      xargs -r -0 ls -l |
      grep -F -q "$owner/$name/$version" \
    && return 0
  done <<<"$(db:index-names)"
  return 1
)

db:index-too-old() (
  +source bashplus/time
  head=$index_file_dir/.git/FETCH_HEAD
  [[ -f $head ]] || return 0
  curr_time=$(+time:epoch)
  pull_time=$(+fs:mtime "$head")
  (( curr_time - (60 * 60) > pull_time ))
)

