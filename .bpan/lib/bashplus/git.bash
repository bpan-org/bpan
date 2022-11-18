+git:assert-in-repo() {
  cd "${1:-.}" ||
    die "Can't 'cd ${1:-.}'"
  +git:in-repo ||
    die "Not in a git repo"
}

+git:branch-name() {
  local name
  +git:assert-in-repo .
  name=$(git rev-parse --abbrev-ref HEAD)
  [[ $name ]] || die
  [[ $name == HEAD ]] && name=''
  echo "$name"
}

+git:commit-sha() {
  +git:assert-in-repo .
  git rev-parse "${1:-HEAD}"
}

+git:has-ref() {
  +git:assert-in-repo .
  git rev-parse "$1" &>/dev/null
}

+git:has-untracked() {
  +git:in-repo &&
  git status |
    grep -q '^Untracked files:'
}

+git:in-repo() {
  +git:is-repo .
}

+git:in-top-dir() [[
  $(pwd -P) == $(+git:top-dir .)
]]

+git:is-clean() {
  ! +git:is-dirty
}

+git:is-dirty() {
  +git:assert-in-repo .
  [[ $(git diff --stat) ]]
}

+git:is-repo() {
  cd "${1:-.}" || die
  git rev-parse --is-inside-work-tree &>/dev/null
}

+git:sha1() {
  git rev-parse "${1?}" 2>/dev/null ||
    die "Can't get commit sha1 for git ref '$1'"
}

+git:subject-lines() {
  +git:assert-in-repo .
  git log --pretty --format='%s' "$@"
}

+git:tag-exists() [[
  $(git tag --list "${1?}") == "$1"
]]

+git:tag-pushed() [[
  -n $(git ls-remote --tags "${2:-origin}" "${1?}")
]]

+git:top-dir() {
  +git:assert-in-repo .
  git rev-parse --show-toplevel
}
