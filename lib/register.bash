register:main() (
  source-once pkg
  pkg:index-update --force


  data=$(cat <<...
{
  "title": "$title",
  "body":  "$body",
  "head":  "$user:repo",
  "base":  "$branch",
  "maintainer_can_modify": true
}
...
)

  : curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer <YOUR-TOKEN>" \
    https://api.github.com/repos/OWNER/REPO/pulls \
    -d '{"title":"Amazing new feature","body":"Please pull these awesome changes in!","head":"octocat:new-feature","base":"master"}'
)
