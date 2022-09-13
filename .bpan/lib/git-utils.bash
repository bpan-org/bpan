git:assert-in-repo() {
  cd "${1:-.}" ||
    die "Can't 'cd ${1:-.}'"
  git:in-repo ||
    die "Not in a git repo"
}

git:in-repo() (
  git:is-repo .
)

git:is-repo() (
  cd "${1:-.}" || die
  git rev-parse --is-inside-work-tree &>/dev/null
)

git:top-dir() (
  git:assert-in-repo .
  git rev-parse --show-toplevel
)

git:in-top-dir() {
  [[ $(pwd -P) == $(git:top-dir .) ]]
}

git:is-clean() (
  ! git:is-dirty
)

git:is-dirty() (
  git:assert-in-repo .
  [[ $(git diff --stat) ]]
)

git:has-ref() (
  git:assert-in-repo .
  git rev-parse "$1" &>/dev/null
)

git:branch-name() (
  git:assert-in-repo .
  name=$(git rev-parse --abbrev-ref HEAD)
  [[ $name ]] || die
  [[ $name == HEAD ]] && name=''
  echo "$name"
)

git:subject-lines() (
  git:assert-in-repo .
  git log --pretty --format='%s' "${1?}"
)

git:commit-sha() (
  git:assert-in-repo .
  git rev-parse "${1:-HEAD}"
)
