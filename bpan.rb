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

post '/star/?' do
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  sender = data['sender']['login']
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

def exxec cmd
  logger.debug cmd
  logger.debug `#{cmd}`
  logger.debug "Exited: #{$?}"
end

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
  authors << author
  authors.uniq!
  authors.sort!
  File.open(AUTHORS_FILE, 'w') {|f|
    f.write authors.to_json
  }
  git.add(File.basename(AUTHORS_FILE))
  git.commit("Add author '#{author}'")
  git.push 'origin', INDEX_BRANCH
end


