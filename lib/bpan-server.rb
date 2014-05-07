require 'logger'
require 'erb'

$stdout.sync = true
LOG = Logger.new($stdout, Logger::DEBUG)

GH_PAGES_BRANCH = 'gh-pages'
GH_PAGES_DIR = File.expand_path(
  File.join(
    File.dirname(__FILE__),
    '..',
    ENV['BPAN_TEST_DIR'] || '',
    GH_PAGES_BRANCH,
  )
)
INDEX_DIR = File.join GH_PAGES_DIR, 'index'
META_DIR = File.join INDEX_DIR, 'package'

def ghpages_file *parts
  File.join(
    GH_PAGES_DIR,
    *parts,
  )
end

def ghpages_index_file file_name
  ghpages_file 'index', file_name
end

AUTHOR_INDEX_FILE = ghpages_index_file 'author.json'
PACKAGE_INDEX_FILE = ghpages_index_file 'package.json'

HOMEPAGE_VIEW = ERB.new(
  File.read File.join ghpages_file, '_cogweb', 'view', 'index.html.erb'
)
HOMEPAGE_FILE = ghpages_file 'index.html'

GIT_REMOTE =
  ENV['BPAN_TEST_REMOTE'] ||
  'git@github.com:bpan-org/bpan.git'

GIT = Git.open GH_PAGES_DIR, log: LOG
if GIT.config('user.name').nil?
  GIT.config 'user.name', 'BPAN'
  GIT.config 'user.email', 'server@bpan.org'
end

def h s
  CGI.escape_html s
end

def body_json req
  JSON.parse req.body.read
rescue
  halt 400, "Invalid JSON"
end

def homepage author
  HOMEPAGE_VIEW.result(binding)
end

def do_lock dirname
  begin
    Dir.mkdir dirname
  rescue
    return
  end
  yield
  Dir.rmdir dirname
end

def XXX *args
  c = caller_locations(1,1)[0].label
  l = caller_locations(1,1)[0].lineno
  args = args.first if args.size == 1
  LOG.info "\nXXX from #{c} #{l}:\n#{YAML.dump args}"
end
