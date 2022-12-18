bpan:get-pkg-vars() {
  pkg_id='' pkg_host='' pkg_owner='' pkg_name=''
  if pkg_id=$(git config --file="$config_file_local" package.id); then
    [[ $pkg_id =~ ^([-a-z0-9]+):([-a-z0-9]+)/([-a-z0-9]+)$ ]] ||
      error "Invalid value for package.id '$pkg_id'"
    pkg_host=${BASH_REMATCH[1]}
    pkg_owner=${BASH_REMATCH[2]}
    pkg_name=${BASH_REMATCH[3]}
    return
  fi

  pkg_name=$(git config --file="$config_file_local" package.name) ||
    error "$config_file_local must contain package.id or package.name"
  pkg_host=$(git config --file="$config_file_local" package.host) || true
  pkg_owner=$(git config --file="$config_file_local" package.owner) || true
  if [[ $pkg_host && $pkg_owner ]]; then
    pkg_id=$pkg_host:$pkg_owner/$pkg_name
    return
  fi

  local url
  if url=$(git config remote.origin.url); then
    if
      [[ $url =~ ^https://github\.com/([-a-z0-9]+)/([-a-z0-9]+)$ ]] ||
      [[ $url =~ ^git@github\.com:([-a-z0-9]+)/([-a-z0-9]+)$ ]]
    then
      pkg_host=${pkg_host:-github}
      pkg_owner=${pkg_owner:-${BASH_REMATCH[1]}}
    fi
  fi
}

ini:match() (
  set "${INI_DEBUG_BASH_X:-+x}"
  ini:data "$@"
  [[ ${#args[*]} -eq 1 ]] ||
    ini:die "ini:all requires 1 key"
  git config --file <(cat "${__ini_files[@]?}") --get-regexp "${args[@]}"
)

ini:first() (
  set "${INI_DEBUG_BASH_X:-+x}"
  read -r key value < <(ini:match "$@")
  [[ $value ]] || return
  echo "$value"
)

ini:first-key() (
  set "${INI_DEBUG_BASH_X:-+x}"
  read -r key value < <(ini:match "$@")
  [[ $key ]] || return
  echo "$key"
)

# uniq with preserved order
+uniq() (
  cat -n |
    sort -u -k2 |
    sort -n |
    cut -f2-
)

+git:commit-sha512() (
  ref=${1:-HEAD}
  {
    printf 'commit %s\0' "$(
      git --no-replace-objects cat-file commit "$ref" | wc -c
    )"
    git cat-file commit HEAD
  } |
    sha512sum |
    cut -d' ' -f1
)

bpan:require-commands() (
  ok=true
  while read -r line; do
    [[ $line ]] || break
    command=${line#require.command.}
    version=${command#*=}
    version=${version%+}
    command=${command%%=*}
    if [[ $version == '0' ]]; then
      +cmd:ok "$command" || {
        ok=false
        if ! ${option_quiet:-false}; then
          echo "warning: command '$command' is required"
        fi
      }
    else
      +cmd:ok-ver "$command" "$version" || {
        ok=false
        if ! ${option_quiet:-false}; then
          echo "warning: command '$command' v$version or higher is required"
        fi
      }
    fi
  done < <(
    ini:list |
      grep "^require\.command\."
  )

  "$ok"
)
