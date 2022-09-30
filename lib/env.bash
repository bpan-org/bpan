env:name() (
  [[ ${name-} ]] ||
    die "'\$name' not defined"
  [[ $name =~ ^[a-z][-a-z0-9]*$ ]] ||
    die "Bad package name '$name'"
  echo "${name%-bash}"
)

env:NAME() (
  [[ ${name-} ]] ||
    die "'\$name' not defined"
  [[ $name =~ ^[a-z][-a-z0-9]*$ ]] ||
    die "Bad package name '$name'"
  NAME=${name%-bash}
  NAME=${NAME^^}
  NAME=${NAME//-/_}
  echo "$NAME"
)

env:pkg() (
  [[ ${name-} ]] ||
    die "'\$name' not defined"
  [[ $name =~ ^[a-z][-a-z0-9]*$ ]] ||
    die "Bad package name '$name'"
  echo "$name"
)

env:PKG() (
  [[ ${name-} ]] ||
    die "'\$name' not defined"
  [[ $name =~ ^[a-z][-a-z0-9]*$ ]] ||
    die "Bad package name '$name'"
  PKG=${name^^}
  PKG=${PKG//-/_}
  echo "$PKG"
)

env:author-name() (
  name=${GIT_AUTHOR_NAME:-$(git config user.name || true)}
  echo "${name:-???}"
)

env:author-email() (
  email=${GIT_AUTHOR_EMAIL:-$(git config user.email || true)}
  echo "${email:-???}"
)

env:copyright-year() (
  if [[ -f .bpan/config ]]; then
    year=$(config:get package.copyright) || true
  fi
  year=${year:-$(date '+%Y')}
  echo "$year"
)

env:date-time() (
  date
)

env:github-user-id() (
  if [[ -f $BPAN_ROOT/config ]]; then
    config_file=$BPAN_ROOT/config
    id=$(config:get github.user) || true
  fi

  if ! [[ $id ]]; then
    rc=0
    out=$(ssh git@github.com 2>&1) || rc=$?
    if [[ $rc -eq 1 ]]; then
      if [[ $out =~ Hi\ ([-a-z0-9]+)! ]]; then
        id=${BASH_REMATCH[1]}
      fi
    fi
  fi

  echo "${id:-github-user-id}"
)

env:github-repo-url() (
  url=$(git config remote.origin.url || echo '???')
  if [[ $url == git@github.com: ]]; then
    url=${url%.git}
    url=https://github.com/${url#git@github.com:}
  fi
  echo "$url"
)

env:github-user-url() (
  user=$(env:github-user-id)
  if [[ $user != '???' ]]; then
    user=https://github.com/$user
  fi
  echo "$user"
)

env:markdown-title() (
  len=${#name}
  line=$(eval "printf '%.0s=' {1..$len}")
  printf '%s\n%s' "$name" "$line"
)

env:readme-title() (
  name=$(env:repo-name)
  len=${#name}
  line=$(eval "printf '%.0s=' {1..$len}")
  printf '%s\n%s' "$name" "$line"
)

env:repo-name() (
  name=$(env:github-repo-url)
  if [[ $name == https://* ]]; then
    name=${name##*/}
  else
    name=$(basename "$(pwd)")
  fi
  echo "$name"
)

