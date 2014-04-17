require 'json'
token = `git config -f ~/.git-hub/config github.api-token`.chomp


json = `curl --silent --request GET https://api.github.com/repos/bpan-org/bpan/stargazers?per_page=1000 --header "Authorization: token #{token}"`

authors = JSON.parse(json)

require './bpan'

authors.collect!{|a| format_author a}

$logger = Logger.new STDOUT
def logger
  $logger
end

git = ensure_branch_updated GH_PAGES_BRANCH
post_process_and_commit_authors git, authors
