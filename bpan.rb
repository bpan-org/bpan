Bundler.require
%w{
  sinatra
  json
  logger
  fileutils
  erb
  yaml
}.each{|l| require l}

$stdout.sync = true
logger = Logger.new($stdout, Logger::DEBUG)

post /\/(star)?\/?/ do
  request.body.rewind  # in case someone already read it
  data = body_json
    
  if data['action'] =~ /^star[ref_type]ed$/
    sender = data['sender']
    logger.debug "Received star from #{sender['login'].inspect}"
    add_author sender
    return "Thanks for starring, #{sender['login']}"
  elsif data['ref_type'] == 'tag'
    created = !data['master_branch'].nil?
    logger.debug "Tag #{data['ref'].inspect} #{created ? 'created' : 'deleted'} on #{data['repository']['clone_url'].inspect}"
    meta = add_package data, created
    return "Thanks for pushing #{meta['name'].inspect} version #{meta['version'].inspect}, sha #{meta['release']['sha']}"
  else
    logger.info data
    halt 400, "Invalid action"
  end
end

post '/push/?' do
  'push'
end

if ENV['RACK_ENV'] == 'development'
  get '/?' do
    ensure_branch_updated GH_PAGES_BRANCH
    File.open(AUTHORS_FILE, 'w+') {|f|f.puts'[]'} unless File.exist?(AUTHORS_FILE)
    authors = JSON.parse(File.read(AUTHORS_FILE))
    homepage(authors)
  end
else
  get '/?' do
    redirect to('http://bpan.org')
  end
end

if %w{development test}.include? ENV['RACK_ENV'] 
  get '/css/jumbotron-narrow.css' do
    content_type 'text/css'
    File.read(File.join(File.dirname(__FILE__), 'views', 'jumbotron-narrow.css'))
  end

  get '/authors.json' do
    ensure_branch_updated GH_PAGES_BRANCH
    File.open(AUTHORS_FILE, 'w+') {|f|f.puts'[]'} unless File.exist?(AUTHORS_FILE)
    return File.read(AUTHORS_FILE)
  end

  get '/packages.json' do
    ensure_branch_updated GH_PAGES_BRANCH
    File.open(PACKAGES_FILE, 'w+') {|f|f.puts'{}'} unless File.exist?(PACKAGES_FILE)
    return File.read(PACKAGES_FILE)
  end
end


private

def branch_dir branch
  File.expand_path(File.join(File.dirname(__FILE__), ENV['BPAN_TEST_DIR'] || '', branch))
end

def h s
  CGI.escape_html s
end

GH_PAGES_BRANCH = 'gh-pages'
INDEX_DIR = 'index'
AUTHORS_FILE = File.join(branch_dir(GH_PAGES_BRANCH), INDEX_DIR, 'author.json')
AUTHORS_FILEP = AUTHORS_FILE+'p'
PACKAGES_FILE = File.join(branch_dir(GH_PAGES_BRANCH), INDEX_DIR, 'package.json')
PACKAGES_FILEP = PACKAGES_FILE + 'p'
HOMEPAGE_VIEW = ERB.new(File.read(File.join(File.dirname(__FILE__), 'views', 'index.html.erb')))
HOMEPAGE_FILE = File.join(branch_dir(GH_PAGES_BRANCH), 'index.html')
GIT_REMOTE = ENV['BPAN_TEST_REMOTE'] || 'git@github.com:bpan-org/bpan.git'

def ensure_dir branch
  return if Dir.exist?(branch_dir branch)
  FileUtils.mkdir_p(branch_dir branch)
  Git.clone(GIT_REMOTE, branch, path: File.dirname(branch_dir(branch)), log: logger)
end

def ensure_branch_updated branch
  ensure_dir branch
  git = Git.open branch_dir(branch), log: logger
  git.checkout(branch)
  git.pull 'origin', branch
  return git
end

def add_author author
  git = ensure_branch_updated GH_PAGES_BRANCH
  File.open(AUTHORS_FILE, 'w+') {|f|f.puts'[]'} unless File.exist?(AUTHORS_FILE)
  authors = JSON.parse(File.read(AUTHORS_FILE))
  authors << format_author(author)
  authors.uniq! {|author| author["login"]}
  authors.sort! {|a,b| a["login"] <=> b["login"]}

  # Regenerate homepage
  File.open(HOMEPAGE_FILE, 'w') {|f|
    f.write homepage(authors)
  }
  git.add(File.basename(HOMEPAGE_FILE))

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
  git.add(AUTHORS_FILE)
  git.add(AUTHORS_FILEP)
  begin
    git.commit("Add author #{author['login'].inspect}")
  rescue Git::GitExecuteError => e
    raise e unless e.message =~ /nothing to commit/i
  end
  git.push 'origin', GH_PAGES_BRANCH

end

def add_package data, created
  return unless created
  meta = nil
  Dir.mktmpdir('bpan_package_clone') do |dir|
    url = data['repository']['clone_url']
    tag = data['ref']
    git = Git.clone(url, tag, path: dir, log: logger, depth: 0)
    git.checkout(tag)
    git.pull 'origin', tag
    meta = YAML.safe_load(File.read(File.join(dir, tag, 'Meta')))
    meta['release'] = {
      'sha' => git.revparse(tag),
      'url' => url,
      'timestamp' => Time.now.to_i
    }
  end

  # Get the exisitng package index
  git = ensure_branch_updated GH_PAGES_BRANCH
  File.open(PACKAGES_FILE, 'w+') {|f|f.puts'{}'} unless File.exist?(PACKAGES_FILE)
  packages = JSON.parse(File.read(PACKAGES_FILE))

  # generate our new entries
  half_qualified_key = [meta['name'], data['repository']['owner']['login']].join('/')
  fully_qualified_key = [half_qualified_key, meta['version']].join('/')

  # update version array
  packages[half_qualified_key] ||= []
  packages[half_qualified_key].unshift meta['version']

  # add full package meta for this version
  packages[fully_qualified_key] = meta

  # set short name if it isn't already taken
  packages[meta['name']] ||= half_qualified_key

  # Regenerate json index
  json = packages.to_json
  File.open(PACKAGES_FILE, 'w') {|f|
    f.write json
  }
  File.open(PACKAGES_FILEP, 'w') {|f|
    f.write "var packages = "
    f.write json
    f.write ";"
  }
  git.add(PACKAGES_FILE)
  git.add(PACKAGES_FILEP)
  begin
    git.commit("Add package #{fully_qualified_key.inspect}")
  rescue Git::GitExecuteError => e
    raise e unless e.message =~ /nothing to commit/i
  end
  git.push 'origin', GH_PAGES_BRANCH

  return meta
end

def homepage authors
  HOMEPAGE_VIEW.result(binding)
end

def format_author author
  { "login" => author['login'],
    "avatar_url" => author["avatar_url"],
    "gravatar_id" => author["gravatar_id"],
    "url" => author["url"],
    "html_url" => author["html_url"],
  }
end

def body_json
  j = request.body.read
  # logger.info j
  JSON.parse j
rescue
  halt 400, "Invalid JSON"
end