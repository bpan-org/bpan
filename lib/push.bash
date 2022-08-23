push:getopt() {
  getopt_spec="\
$app [<$app-opts>] $command <key> [<value>]

'$app $command' Options:
--
f,force       Force push
t,tag=        Tag to use

h,help        Get help for $command command
"
}

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

