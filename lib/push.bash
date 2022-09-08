push:getopt() (
  echo "\
$app [<$app-opts>] $cmd <key> [<value>]

'$app $cmd' Options:
--
f,force       Force push
t,tag=        Tag to use

h,help        Get help for $cmd command
"
)

push:main() (
  bpan:config-read .bpan/config

  [[ $(git diff --stat) ]] &&
    error "Can't push repo with uncommitted changes"

  branch=$(git rev-parse --abbrev-ref HEAD)
  [[ $branch == HEAD ]] &&
    error "Can't push. Not checked out to a branch."

  tag=$(bpan:config bpan.version)
  [[ $tag ]] ||
    error "No config 'bpan.version' to make tag with." \
      "Try --tag=..."

  if [[ -f Changes ]]; then
    change_version=$(
      git config -f Changes --get-regexp '^version\.' | head -n1
    )
    change_version=${change_version#version.}
    change_version=${change_version%%.d*}

    if [[ $change_version ]]; then
      [[ $tag == "$change_version" ]] ||
        error "Package version '$tag' does not match Changes version '$change_version'"
    fi
  fi

  if $option_force; then
    (
      set -x
      git push origin ":$tag" || true
    )
  elif [[ $(git tag -l "$tag") ]]; then
    error "Tag '$tag' already exists. Try --force."
  fi

  (
    set -x
    git tag --force "$tag"
    git push --force-with-lease --tag origin "$branch"
  )
)
