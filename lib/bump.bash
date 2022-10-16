bump:options() (cat <<...
push      Push changes upstream
publish   Publish to BPAN index after bump
version=  New version string
...
)

bump:main() (
  if $option_publish; then
    option_push=true
  fi

  if $option_quiet; then
    bpan='bpan --quiet'
  else
    bpan=bpan
  fi

  old_version=$(bump:old-version)
  new_version=$(bump:new-version)

  bump:check-sanity

  say -y "Running 'bpan update'"
  $bpan update

  say -y "Running 'bpan test'"
  $bpan test

  say -y "Bumping to version '$new_version'"

  bump:update-changes-file
  bump:update-config-file
  bump:update-version-vars

  git commit -q -a -m "Version $new_version"

  commit=$(git:commit-sha)
  say -y "Changes committed '${commit:0:8}'"

  git tag "$new_version"
  say -y "Commit tagged as '$new_version'"

  if $option_push; then
    bump:push
  fi

  say -g "Version bump complete"

  echo

  [[ $old_version == 0.0.0 ]] \
    && rev_list="..$new_version" \
    || rev_list="$old_version^..$new_version"

  say -y Commits:
  git log --pretty=oneline "$rev_list"

  name=$(ini:get --file=.bpan/config package.name)
  if $option_publish && [[ $name != bpan ]]; then
    say -y "Running 'bpan publish'"
    $bpan publish
  fi
)

bump:check-sanity() (
  +assert-perl

  git:in-top-dir ||
    error "'$app $cmd' must be at repo toplevel"
  git:is-clean ||
    error "Can't '$app $cmd' with uncommited changes"
  if [[ $old_version != 0.0.0 ]]; then
    git:tag-exists "$old_version" ||
      error "No tag for current version '$old_version'"
  fi

  [[ -f Changes ]] ||
    error "'$app $cmd' require './Changes' file"
  [[ -f .bpan/config ]] ||
    error "'$app $cmd' require '.bpan/config' file"

  git:tag-exists "$new_version" &&
    error "Can't bump. Tag '$new_version' already exists."

  list=$(bump:change-list)

  grep -q -i '^done = wip\>' <<<"$list" &&
    error "Can't '$app $cmd' with WIP commits"

  if $option_push; then
    branch=$(git:branch-name)
    [[ $branch ]] ||
      error "Can't push. Not checked out to a branch."
    publish_branch=$(ini:get --file=.bpan/config package.branch || echo main)
    [[ $branch == "$publish_branch" ]] ||
      error "Can't push. Current branch is not '$publish_branch'"
  fi

  if ! [[ $list ]]; then
    if $option_push; then
      bump:push
      return
    fi
    error "No changes commited since version '$old_version'"
  fi
)

bump:change-list() (
  (
    if [[ $old_version == 0.0.0 ]]; then
      git:subject-lines
    else
      git:subject-lines "$old_version.."
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
  $bpan config --local package.version "$new_version"

  say -y "Updated '.bpan/config' file to '$new_version'"
)

bump:update-version-vars() (
  for file in $(shopt -s nullglob; echo bin/* lib/*); do
    temp=$(+mktemp)
    perl -pe 's/^(\s*VERSION)=\d+\.\d+\.\d+(.*)/$1='"$new_version"'$2/' \
      < "$file" > "$temp"
    if [[ -x $file ]]; then
      chmod '=rwx' "$temp"
    else
      chmod '=rw' "$temp"
    fi
    if +is-file-diff "$file" "$temp"; then
      mv "$temp" "$file"
      say -y "Updated VERSION=... in '$file'"
    fi
  done
)

bump:old-version() (
  [[ -f .bpan/config ]] ||
    error "Config file '.bpan/config' not found"

  version=$($bpan config --local package.version)

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
    version=$($bpan config --local package.version) ||
      error "Can't get 'package.version' from '.bpan/confg'"

    if [[ $version == 0.0.0 ]]; then
      echo "0.1.0"

    else
      echo "${version%.*}.$(( ${version##*.} + 1))"
    fi
  fi
)

bump:push() (
  branch=$(git:branch-name)
  git push -q --tag origin "$branch"
  say -y "Pushed to origin '$branch'"
)
