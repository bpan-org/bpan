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

def XXX *args
  c = caller_locations(1,1)[0].label
  l = caller_locations(1,1)[0].lineno
  args = args.first if args.size == 1
  logger.info "\nXXX from #{c} #{l}:\n#{YAML.dump args}"
end

post '/?' do
  request.body.rewind  # in case someone already read it
  data = body_json

  if data['action'] =~ /^star[ref_type]ed$/
    sender = data['sender']
    logger.debug "Received star from #{sender['login'].inspect}"
    add_author sender
    return "Thanks for starring, #{sender['login']}"
  elsif data['ref_type'] == 'tag'
    created = !data['master_branch'].nil?
    logger.debug "Tag %s %s on %s" % [
      data['ref'].inspect,
      (created ? 'created' : 'deleted'),
      data['repository']['clone_url'].inspect,
    ]
    return 'Deleted tag' unless created
    meta = add_package data
    return "Thanks for pushing %s version %s sha %s" % [
      meta['name'].inspect,
      meta['version'].inspect,
      meta['release']['sha'],
    ]
  else
    logger.info data
    halt 400, "Invalid action"
  end
end

post '/rebuild/' do
  author = JSON.parse(File.read(AUTHOR_FILE))
  post_process_and_commit_author author
  msg = "Successful rebuild of indexes and webpage"
  logger.info msg
  return "#{msg}\n"
end

if ENV['RACK_ENV'] == 'development'
  get '/?' do
    File.open(AUTHOR_FILE, 'w+') {|f|f.puts'[]'} \
      unless File.exist?(AUTHOR_FILE)
    author = JSON.parse(File.read(AUTHOR_FILE))
    homepage(author)
  end
else
  get '/?' do
    redirect to('http://bpan.org')
  end
end

if %w{development test}.include? ENV['RACK_ENV']
  get '/css/jumbotron-narrow.css' do
    content_type 'text/css'
    File.read(
      File.join(
        File.dirname(__FILE__),
        'views',
        'jumbotron-narrow.css',
      )
    )
  end

  get '/author.json' do
    File.open(AUTHOR_FILE, 'w+') {|f|f.puts'[]'} \
      unless File.exist?(AUTHOR_FILE)
    return File.read(AUTHOR_FILE)
  end

  get '/package.json' do
    File.open(PACKAGE_FILE, 'w+') {|f|f.puts'{}'} \
      unless File.exist?(PACKAGE_FILE)
    return File.read(PACKAGE_FILE)
  end
end

#------------------------------------------------------------------------------
private

def h s
  CGI.escape_html s
end

GH_PAGES_BRANCH = 'gh-pages'
GH_PAGES_DIR = File.expand_path(
  File.join(
    File.dirname(__FILE__),
    ENV['BPAN_TEST_DIR'] || '',
    GH_PAGES_BRANCH,
  )
)
GIT_REMOTE =
  ENV['BPAN_TEST_REMOTE'] ||
  'git@github.com:bpan-org/bpan.git'

if not Dir.exist?(GH_PAGES_DIR)
  Git.clone(
    GIT_REMOTE,
    GH_PAGES_BRANCH,
    path: File.dirname(GH_PAGES_DIR),
    log: logger,
  )
  fail unless Dir.exist?(GH_PAGES_DIR)
end

GIT = Git.open GH_PAGES_DIR, log: logger
GIT.checkout(GH_PAGES_BRANCH)
GIT.pull 'origin', GH_PAGES_BRANCH

def ghpages_file *parts
  File.join(
    GH_PAGES_DIR,
    *parts,
  )
end

def ghpages_index_file file_name
  ghpages_file 'index', file_name
end

AUTHOR_FILE = ghpages_index_file 'author.json'
AUTHOR_FILEP = "#{AUTHOR_FILE}p"
PACKAGE_FILE = ghpages_index_file 'package.json'
PACKAGE_FILEP = "#{PACKAGE_FILE}p"
HOMEPAGE_VIEW = ERB.new(
  File.read(ghpages_file 'views', 'index.html.erb')
)
HOMEPAGE_FILE = ghpages_file 'index.html'

def add_author sender
  File.open(AUTHOR_FILE, 'w') {|f|f.puts'[]'} \
    unless File.exist?(AUTHOR_FILE)
  author = JSON.parse(File.read(AUTHOR_FILE))
  author << format_author(sender)
  post_process_and_commit_author author, sender
end

def post_process_and_commit_author author, hash=nil
  author.uniq! {|a| a["login"]}
  author.sort! {|a,b| a["login"] <=> b["login"]}

  # Regenerate homepage
  File.open(HOMEPAGE_FILE, 'w') {|f|
    f.write homepage(author)
  }
  GIT.add(File.basename(HOMEPAGE_FILE))

  # Regenerate json index
  json = JSON.pretty_generate author
  File.open(AUTHOR_FILE, 'w') {|f|
    f.write json
  }
  File.open(AUTHOR_FILEP, 'w') {|f|
    f.write "var author = "
    f.write json
    f.write ";"
  }
  GIT.add(AUTHOR_FILE)
  GIT.add(AUTHOR_FILEP)
  begin
    message = if hash
      "[BPAN] Add author #{hash['login'].inspect}"
    else
      "[BPAN] Prune/resync author directory"
    end
    GIT.commit(message)
  rescue Git::GitExecuteError => e
    raise e unless e.message =~ /nothing to commit/i
  end
  GIT.push 'origin', GH_PAGES_BRANCH

  package = load_package
  save_package package
end

def add_package data
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

  # Get the existing package index
  package = load_package

  # generate our new entries
  half_qualified_key = [
    meta['name'],
    data['repository']['owner']['login'],
  ].join('/')
  fully_qualified_key = [
    half_qualified_key,
    meta['version'],
  ].join('/')

  # update version array
  package[half_qualified_key] ||= []
  package[half_qualified_key] = [package[half_qualified_key]] \
    if package[half_qualified_key].instance_of? String
  package[half_qualified_key].unshift meta['version']

  # add full package meta for this version
  package[fully_qualified_key] = meta

  # set short name if it isn't already taken
  package[meta['name']] ||= half_qualified_key

  save_package package, fully_qualified_key

  return meta
end

def load_package
  File.open(PACKAGE_FILE, 'w+') {|f|f.puts'{}'} \
    unless File.exist?(PACKAGE_FILE)
  JSON.parse(
    File.open(PACKAGE_FILE, "r:UTF-8", &:read)
  )
end

def save_package package, fully_qualified_key=nil
  # Regenerate json index. Pretty printed and top keys sorted.
  json = JSON.pretty_generate Hash[
    package.keys.sort.map{|k|[k,package[k]]}
  ]
  File.open(PACKAGE_FILE, 'w') {|f|
    f.write json
  }
  File.open(PACKAGE_FILEP, 'w') {|f|
    f.write "var package = "
    f.write json
    f.write ";"
  }
  GIT.add(PACKAGE_FILE)
  GIT.add(PACKAGE_FILEP)
  begin
    if fully_qualified_key
      GIT.commit("[BPAN] Add package #{fully_qualified_key.inspect}")
    else
      logger.debug "Regenerating package.json"
    end
  rescue Git::GitExecuteError => e
    raise e unless e.message =~ /nothing to commit/i
  end
  GIT.push 'origin', GH_PAGES_BRANCH
end

def homepage author
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
