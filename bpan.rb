Bundler.require
require 'sinatra'
require 'json'
require 'logger'
require 'fileutils'

$stdout.sync = true
logger = Logger.new $stdout, Logger::DEBUG

INDEX_DIR = File.join(File.dirname(__FILE__), 'index')
INDEX_BRANCH = 'index'
AUTHORS_FILE = File.join(INDEX_DIR, 'authors.json')
AUTHORS_FILEP = AUTHORS_FILE+'p'

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

def ensure_index_dir
  return if Dir.exist?(INDEX_DIR)
  FileUtils.mkdir_p(INDEX_DIR)
  Git.clone('git@github.com:bpan-org/bpan-org.git', 'index', path: File.dirname(__FILE__), log: logger)
end

def repo
  g = Git.open INDEX_DIR, log: logger
  g.branch(INDEX_BRANCH).checkout
  g.config('user.name', 'BPAN index')
  g.config('user.email', 'index@bpan.org')
  return g
end

def ensure_index_updated
  ensure_index_dir
  repo.pull 'origin', INDEX_BRANCH
  return repo
end

def add_author author
  git = ensure_index_updated
  authors = JSON.parse(File.read(AUTHORS_FILE))
  authors << format_author(author)
  authors.uniq! {|author| author["login"]}
  authors.sort! {|a,b| a["login"] <=> b["login"]}
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
  git.commit("Add author '#{author}'")
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


