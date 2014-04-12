Bundler.require
require 'sinatra'
require 'json'
require 'logger'
require 'fileutils'
require 'erb'

$stdout.sync = true
logger = Logger.new $stdout, Logger::DEBUG

post '/star/?' do
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  sender = data['sender']
  logger.debug "Received star from #{sender.inspect}"
  add_author sender
  "Thanks for starring, #{sender}"
end

post '/push/?' do
  'push'
end

get '/?' do
  redirect to('http://bpan.org')
end

private

def branch_dir branch
  File.join(File.dirname(__FILE__), branch)
end

INDEX_BRANCH = 'index'
GH_PAGES_BRANCH = 'gh-pages'
AUTHORS_FILE = File.join(branch_dir(INDEX_BRANCH), 'authors.json')
AUTHORS_FILEP = AUTHORS_FILE+'p'
HOMEPAGE_VIEW = ERB.new(File.read(File.join(File.dirname(__FILE__), 'views', 'index.html.erb')))
HOMEPAGE_FILE = File.join(branch_dir(GH_PAGES_BRANCH), 'index.html')

def ensure_dir branch
  return if Dir.exist?(branch_dir branch)
  FileUtils.mkdir_p(branch_dir branch)
  Git.clone('git@github.com:bpan-org/bpan-org.git', branch, path: File.dirname(__FILE__), log: logger)
end

def repo(branch)
  g = Git.open branch_dir(branch), log: logger
  g.branch(branch).checkout
  g.config('user.name', 'BPAN index')
  g.config('user.email', 'index@bpan.org')
  return g
end

def ensure_branch_updated branch
  ensure_dir branch
  repo(branch).pull 'origin', branch
  return repo(branch)
end

def add_author author
  git = ensure_branch_updated INDEX_BRANCH
  authors = JSON.parse(File.read(AUTHORS_FILE))
  authors << format_author(author)
  authors.uniq! {|author| author["login"]}
  authors.sort! {|a,b| a["login"] <=> b["login"]}

  # Regenerate homepage
  git_gh = ensure_branch_updated GH_PAGES_BRANCH
  File.open(HOMEPAGE_FILE, 'w') {|f|
    f.write HOMEPAGE_VIEW.result(binding)
  }
  git_gh.add(File.basename(HOMEPAGE_FILE))
  begin
    git_gh.commit("Add author #{author['login'].inspect}")
  rescue Git::GitExecuteError => e
    raise e unless e.message =~ /nothing to commit/i
  end
  git_gh.push 'origin', GH_PAGES_BRANCH

  # Regenerate json index
  json = authors.to_json
  File.open(AUTHORS_FILE, 'w') {|f|
    f.write json
  }
  File.open(AUTHORS_FILEP, 'w') {|f|
    f.write "var authors = "
    f.write json
    f.write ";"
  }
  git.add(File.basename(AUTHORS_FILE))
  git.add(File.basename(AUTHORS_FILEP))
  begin
    git.commit("Add author #{author['login'].inspect}")
  rescue Git::GitExecuteError => e
    raise e unless e.message =~ /nothing to commit/i
  end
  git.push 'origin', INDEX_BRANCH

end

def format_author author
  { "login" => author['login'],
    "avatar_url" => author["avatar_url"],
    "gravatar_id" => author["gravatar_id"],
    "url" => author["url"],
    "html_url" => author["html_url"],
  }
end


