register:main() (
  # check inside a git repo

  : curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer <YOUR-TOKEN>" \
    https://api.github.com/repos/OWNER/REPO/pulls \
    -d '{"title":"Amazing new feature","body":"Please pull these awesome changes in!","head":"octocat:new-feature","base":"master"}'
)
