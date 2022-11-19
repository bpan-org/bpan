bump:options() (cat <<...
push      Push changes upstream
publish   Publish to BPAN index after bump
version=  New version string
dryrun    Don't tag, commit or push
...
)

bump:main() (
  bump:check-repo

  if $option_publish; then
    option_push=true
  fi

  package_name=$(ini:get --file=.bpan/config package.name)

  old_version=$(bump:old-version)
  new_version=$(bump:new-version)

  change_list=$(bump:change-list)

  if [[ ! $change_list ]]; then
    if $option_push; then
      say -y "No changes. Not bumping version."
    else
      error "No changes commited since version '$old_version'"
    fi

  else
    bump:check-sanity || return 0

    say -y "Bumping to version '$new_version'"
    bump:update-config-file
    bump:update-changes-file
    bump:update-version-vars

    say -y "Running 'bpan update'"
    bpan-run update

    say -y "Running 'bpan test'"
    bpan-run test

    if $option_dryrun; then
      echo
      say -y "*** DRYRUN BUMP COMPLETE ***"
      return
    fi

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

    say -y Commits:
    git log --pretty=oneline "$rev_list"
  fi

  if $option_push; then
    bump:push
  fi

  if $option_publish && [[ $package_name != bpan ]]; then
    say -y "Running 'bpan publish'"
    bpan-run publish
  fi
)

bump:check-repo() (
  +git:in-top-dir ||
    error "'$app $cmd' must be at repo toplevel"
  +git:is-clean ||
    error "Can't '$app $cmd' with uncommited changes"
)

bump:check-sanity() (
  pushed=false

  if [[ $old_version != 0.0.0 ]]; then
    +git:tag-exists "$old_version" ||
      error "No tag for current version '$old_version'"
  fi

  [[ -f Changes ]] ||
    error "'$app $cmd' require './Changes' file"
  [[ -f .bpan/config ]] ||
    error "'$app $cmd' require '.bpan/config' file"

  +git:tag-exists "$new_version" &&
    error "Can't bump. Tag '$new_version' already exists."

  grep -q -i '^done = wip\>' <<<"$change_list" &&
    error "Can't '$app $cmd' with WIP commits"

  if $option_push; then
    branch=$(+git:branch-name)
    [[ $branch ]] ||
      error "Can't push. Not checked out to a branch."
    publish_branch=$(ini:get --file=.bpan/config package.branch || echo main)
    [[ $branch == "$publish_branch" ]] ||
      error "Can't push. Current branch is not '$publish_branch'"
  fi
)

bump:change-list() (
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

bump:update-changes-file() (
  entry="\
[version \"$new_version\"]
date = $(date)
$(bump:change-list)"

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

bump:update-config-file() (
  if [[ $package_name == bpan && -f etc/config ]]; then
    ini:set --file=etc/config bpan.version "$new_version"
  fi

  # shellcheck disable=2153
  ini:set --file=.bpan/config bpan.version "$VERSION"

  ini:set --file=.bpan/config package.version "$new_version"

  say -y "Updated '.bpan/config' file to '$new_version'"
)

bump:update-version-vars() (
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

bump:old-version() (
  [[ -f .bpan/config ]] ||
    error "Config file '.bpan/config' not found"

  version=$(ini:get package.version)

  [[ $version ]] ||
    error "No 'package.version' found in BPAN config file"

  [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
    error "Unrecognized version '$version'"

  echo "$version"
)

bump:new-version() (
  if [[ $option_version && $option_version != false ]]; then
    echo "$option_version"

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

bump:push() (
  branch=$(+git:branch-name)
  git push -q --tag origin "$branch"
  say -y "Pushed to origin '$branch'"
)
