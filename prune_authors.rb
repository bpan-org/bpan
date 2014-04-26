require 'json'
token = `git config -f ~/.git-hub/config github.api-token`.chomp


json = `curl --silent --request GET https://api.github.com/repos/bpan-org/bpan/stargazers?per_page=1000 --header "Authorization: token #{token}"`

author = JSON.parse(json)

require './bpan'

author.collect!{|a| format_author a}

$logger = Logger.new STDOUT
def logger
  $logger
end

ensure_ghpages_branch_updated
post_process_and_commit_author author
