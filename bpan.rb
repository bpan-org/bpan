Bundler.require
require 'sinatra'
require 'json'
require 'logger'

$stdout.sync = true
logger = Logger.new $stdout

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

SSH_KEY_FILE = File.join(ENV['HOME'], '.ssh', 'server.id_rsa')
SSH_CONFIG = File.join(ENV['HOME'], '.ssh', 'config')
def ensure_ssh
  return if File.exist?(SSH_KEY_FILE)
  File.open(SSH_KEY_FILE, 'w+') do |f|
    f.write ENV['GIT_PRIVKEY']
  end
  File.open(SSH_CONFIG, 'w') do |f|
    f.write <<-EOF
    Host bpan.github.com
      HostName github.com
      PreferredAuthentications publickey
      IdentityFile #{SSH_KEY_FILE}
    EOF
  end
end

def ensure_index_dir
  ensure_ssh
  return if Dir.exist?(INDEX_DIR)
  require 'fileutils'
  FileUtils.mkdir_p(INDEX_DIR)
  Git.clone('git@bpan.github.com:bpan-org/bpan-org.git', 'index', path: File.dirname(__FILE__), log: logger)
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


