release:main() (
  git:in-repo ||
    error "Not in a git repo"
  [[ -f .bpan/config ]] ||
    error "Not in a BPAN package repo"

  token=$(config:get bpan.user.token) || true
  if [[ -z $token || $token == ___ ]]; then
    error "Missing or invalid bpan.user.token in $BPAN_ROOT/config"
  fi

  url=$(git config remote.origin.url) ||
    error "Can't find 'remote.origin.url' in .git/config"

  regex='^git@github.com:(.+)/(.+)$'
  [[ $url =~ $regex ]] ||
    error "'$url' does not match '$regex'"

  user=${BASH_REMATCH[1]}
  repo=${BASH_REMATCH[2]}

  package=github:$user/$repo

  if [[ $package == github:bpan-org/bpan ]]; then
    error "Can't release '$package'. Not a package."
  fi

  version=$(config:get bpan.version) ||
    error "Can't find 'bpan.version' in .bpan/config"

  body="\
Please update the BPAN Index for:

'''
package: $package
version: $version
'''
"

  body=${body//\'/\`}
  body=${body//$'\n'/\\n}

  github_url=https://api.github.com/repos/bpan-org/bpan-index-testing/issues/1/comments

  url=$(
    $option_verbose && set -x
    curl \
      --silent \
      --request POST \
      --header "Accept: application/vnd.github+json" \
      --header "Authorization: Bearer $token" \
      $github_url \
      --data "{\"body\":\"$body\"}" |
    grep '"html_url"' |
    head -n1 |
    cut -d'"' -f4
  ) || true

  [[ $url ]] ||
    error "Release request failed"

  say -g "Release for '$package' version '$version' requested"
  echo
  say -y "  $url"
)
