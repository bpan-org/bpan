env:author-name() (
  name=${GIT_AUTHOR_NAME:-$(git config user.name || true)}
  echo "${name:-???}"
)

env:author-email() (
  email=${GIT_AUTHOR_EMAIL:-$(git config user.email || true)}
  echo "${email:-???}"
)

env:copyright-year() (
  year=$(bpan config bpan.copyright)
  echo "${year:-$(date +%Y)}"
)

env:date-time() (
  date
)

env:github-user-id() (
  if id=$(git hub config login 2>/dev/null); then
    echo "$id"
    return
  fi
  id=$(env:github-repo-url)
  if [[ $id == https://* ]]; then
    id=${id%/*}
    id=${id##*/}
  fi
  echo "$id"
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

