# TODO redirect from https://bpan.org/publish-requests

publish:options() (cat <<...
I,index=    Index name to register to

check       Just run sanity checks. Don't publish
bump?       Bump files to next version, but don't push
register    Register a new package to a $APP index
...
)

publish:main() (
  +git:is-dirty &&
    error "Can't '$app $cmd' with uncommitted changes"

  old_version=$(publish:old-version)
  new_version=$(publish:new-version)
  change_list=$(publish:change-list)

  if [[ $option_bump ]]; then
    [[ $change_list ]] || error \
      "Can't bump version." \
      "No changes commited since version '$old_version'"

    publish:bump "$@"

  elif $option_register; then
    if [[ $change_list ]]; then
      publish:bump "$@"
      publish:push
      do-ini-init
    fi

    publish:source-plugin
    publish:register "$@"

  else
    bpan:get-pkg-vars
    package_name=$pkg_name

    if [[ $change_list ]]; then
      publish:bump "$@"
      publish:push
      do-ini-init
    fi

    [[ $package_name == bpan ]] && return

    publish:source-plugin
    publish:run "$@"
  fi
)

publish:source-plugin() {
  source-once util/db

  db:source-plugin publish || {
    # shellcheck disable=2046
    set -- $(db:index-names)
    if [[ $# -eq 1 ]]; then
      error "Please specify --register"
    else
      error \
        "More than 1 index in configuration:" \
        "$@" \
        "Please specify --index=..."
    fi
  }
}

publish:old-version() (
  [[ -f $config_file_local ]] ||
    error "Config file '$config_file_local' not found"

  version=$(ini:get package.version)

  [[ $version ]] ||
    error "No 'package.version' found in BPAN config file"

  [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    error "Unrecognized version '$version'"

  echo "$version"
)

publish:new-version() (
  if [[ $option_bump && $option_bump != true ]]; then
    version=$option_bump
    [[ ${version-} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
      error "Invalid bump version '$version'"

    echo "$version"

  else
    version=$(ini:get package.version) ||
      error "Can't get 'package.version' from '.bpan/confg'"

    if [[ $version == 0.0.0 ]]; then
      echo "0.1.0"

    else
      echo "${version%.*}.$(( ${version##*.} + 1))"
    fi
  fi
)

publish:change-list() (
  (
    if [[ $old_version == 0.0.0 ]]; then
      +git:subject-lines
    else
      +git:subject-lines "$old_version.."
    fi
  ) |
    while read -r line; do
      echo "done = $line"
    done
)

publish:push() (
  branch=$(+git:branch-name)
  git push -q --tag origin "$branch"
  say -y "Pushed to origin '$branch'"
)


#------------------------------------------------------------------------------
# Publish Common Logic
#------------------------------------------------------------------------------

publish:setup() {
  +git:in-repo ||
    error "Not in a git repo"

  [[ -f .bpan/config ]] ||
    error "Not in a $APP package repo"

  bpan:get-pkg-vars
  [[ $pkg_name != "$app" ]] ||
    error "Can't use '$app publish' for '$app'."

  db:get-package-host-owner-name
  package_id=$host:$owner/$name

  force_update=true db:sync

  package=$host:$owner/$name

  version=$(ini:get package.version) ||
    error "Can't find 'package.version' in .bpan/config"

  [[ $version != 0.0.0 ]] ||
    error "Can't publish version '0.0.0'." \
          "Try '$app bump'."

  commit=$(+git:sha1 "$version")
}

publish:check() (
  package_id=$package \
    publish:check-version-bump "$version"

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

  ini:get --file="$index_file_path" \
    package."$package".v"${version//./-}" >/dev/null &&
      error "$package version '$version' already published"

  say -y "Running tests"
  BASHPLUS_DEBUG_STACK='' bpan-run test
  echo
)

publish:check-version-bump() (
  version=$1
  indexed_version=$(
    git config -f "$index_file_path" \
      "package.$package_id.version"
  )
  +source bashplus/version
  +version:gt "$version" "$indexed_version" ||
    error \
      "'$package_id' version '$version' not greater than indexed version"
)

publish:add-new-index-entry() (
  entry="[package \"$package_id\"]"

  cd "$index_file_dir" || exit
  (
    updated=false
    while IFS='' read -r line; do
      if ! $updated && [[ $line == '[package'* && $entry < "$line" ]]
      then
        echo "$entry"
        echo
        updated=true
      fi
      echo "$line"
    done < "$index_file_name"
    if ! $updated; then
      echo
      echo "$entry"
    fi
  ) > index
  mv index "$index_file_name"

  ini:set --file="$index_file_name" "package.$package_id.title" ...
  ini:set --file="$index_file_name" "package.$package_id.version" 0.0.0
  # shellcheck disable=2153
  ini:set --file="$index_file_name" bpan.version "$VERSION"
  ini:set --file="$index_file_name" bpan.updated "$bpan_run_timestamp"
)

publish:new-index-entry() (
  package_version_key=${package_version//./-}
  entry=$(< "$root/share/template/index-entry.ini")
  while [[ $entry =~ \[%\ ([^%]*)\ %\] ]]; do
    prev=$entry
    expr=${BASH_REMATCH[1]%%\ }
    eval "value=$expr"
    entry=${entry/"[% $expr %]"/$value}
  done

  grep -v '^$' <<<"$entry"
)

publish:update-index() (
  action=${1?Action verb required}

  package_author=$(publish:get-package-author)

  ini:init "$index_file_path"

  package_title=$(git config -f .bpan/config package.title)
  package_version=$(git config -f .bpan/config package.version)
  package_license=$(git config -f .bpan/config package.license)
  package_tag=$(git config -f .bpan/config package.tag)
  package_commit=$(+git:commit-sha "$package_version")
  package_sha512=$(+git:commit-sha512 "$package_version")

  [[ ${#package_commit} -eq 40 ]] ||
    die "Can't get commit for '$package_id' v$package_version"

  # TODO Update all relevant fields

  ini:set "package.$package_id.title"   "$package_title"
  ini:set "package.$package_id.version" "$package_version"
  ini:set "package.$package_id.license" "$package_license"
  ini:set "package.$package_id.tag"     "$package_tag"
  ini:set "package.$package_id.author"  "$package_author"
  ini:set "package.$package_id.update"  "$bpan_run_timestamp"
  ini:set "package.$package_id.commit"  "$package_commit"
  ini:set "package.$package_id.sha512"  "$package_sha512"

  # shellcheck disable=2153
  ini:set bpan.version "$VERSION"
  ini:set bpan.updated "$bpan_run_timestamp"

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
$action $package_id=$package_version

    package=$package_id
    title=\"$package_title\"
    version=$package_version
    license=$package_license
    author=$package_author
    commit=$package_commit
    sha512=$package_sha512
"
  message=${message//\'\'\'/\`\`\`}

  git -C "$index_file_dir" \
    commit --quiet --all --message="$message"
)

publish:get-package-author() (
  author_id=$(
    ini:first-key '^author\..*\.name$' |
      cut -d. -f2
  ) || error "No author.*.name entry in config"
  [[ $author_id == *:* ]] ||
    error "Invalid author section key '[author \"$author_id\"]'" \
      "Should be '[author \"<host-name>:<host-user-id>\"]'"
  author_host=${author_id%:*}
  author_user=${author_id#*:}

  package_author=$(
    ini:vars user
    user=$author_user
    ini:get --file="$index_file_path" "host.$author_host.author"
  ) || error "No 'host.$author_host.author' entry in '$index' index"

  echo "$package_author"
)


#------------------------------------------------------------------------------
# Bump logic
#------------------------------------------------------------------------------
publish:bump() (
  publish:check-repo

  bpan:get-pkg-vars
  package_name=$pkg_name

  publish:check-bump-ok

  say -y "Bumping to version '$new_version'"
  publish:update-config-file
  publish:update-changes-file
  publish:update-version-vars

  say -y "Running 'bpan update'"
  bpan-run update

  say -y "Running 'bpan test'"
  BASHPLUS_DEBUG_STACK='' bpan-run test

  git commit -q -a -m "Version $new_version"

  commit=$(+git:commit-sha)
  say -y "Changes committed '${commit:0:8}'"

  git tag "$new_version"
  say -y "Commit tagged as '$new_version'"

  say -g "Version bump complete"
  echo

  [[ $old_version == 0.0.0 ]] \
    && rev_list="..$new_version" \
    || rev_list="$old_version^..$new_version"

  say -g "Commits for version '$new_version':"
  git log --pretty=oneline "$rev_list"
)

publish:check-repo() (
  +git:in-top-dir ||
    error "'$app $cmd' must be at repo toplevel"
  +git:is-clean ||
    error "Can't '$app $cmd' with uncommited changes"
)

publish:check-bump-ok() (
  pushed=false

  if [[ $old_version != 0.0.0 ]]; then
    +git:tag-exists "$old_version" ||
      error "No tag for current version '$old_version'"
  fi

  [[ -f Changes ]] ||
    error "'$app $cmd' require './Changes' file"
  [[ -f $config_file_local ]] ||
    error "'$app $cmd' require '$config_file_local' file"

  +git:tag-exists "$new_version" &&
    error "Can't bump. Tag '$new_version' already exists."

  grep -q -i '^done = wip\>' <<<"$change_list" &&
    error "Can't '$app $cmd' with WIP commits"

  true
)

publish:update-changes-file() (
  entry="\
[version \"$new_version\"]
date = $bpan_run_timestamp
$change_list"

  if [[ $old_version == 0.0.0 ]]; then
    changes=''
  else
    changes=$(< Changes)
  fi

  (
    echo "$entry"
    if [[ $changes ]]; then
      echo
      echo "$changes"
    fi
  ) > Changes

  say -y "Updated 'Changes' file"
)

publish:update-config-file() (
  # shellcheck disable=2153
  ini:set --file="$config_file_local" bpan.version "$VERSION"
  ini:set --file="$config_file_local" package.version "$new_version"

  if [[ $package_name == bpan && -f $config_file_system ]]; then
    ini:set --file="$config_file_local" bpan.version "$new_version"
    ini:set --file="$config_file_global" bpan.version "$new_version"
    ini:set --file="$config_file_system" bpan.version "$new_version"
  fi

  say -y "Updated '$config_file_local' file to '$new_version'"
)

publish:update-version-vars() (
  while read -r file; do
    grep -q -i "version.*${old_version//./\\.}" "$file" ||
      continue

    text=$(< "$file")
    orig=$text

    text=${text//$old_version/$new_version}

    if [[ $text != "$orig" ]]; then
      echo "$text" > "$file"
      say -y \
        "Updated version in file '$file'"
    fi
  done < <(
    [[ -d bin ]] && find bin -type f
    [[ -d lib ]] && find lib -type f
  )
)
