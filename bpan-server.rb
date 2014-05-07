Bundler.require
require 'sinatra'
require 'json'
require 'fileutils'
require 'yaml'
require_relative './lib/bpan-server'

LOG.info "Initialize server thread"

post '/?' do
  request.body.rewind  # in case someone already read it
  data = body_json request

  if data['action'] == 'started'
    add_author data
  elsif data['ref_type'] == 'tag'
    add_package data
  else
    LOG.info data
    halt 400, "Invalid action"
  end
end

post '/rebuild/' do
  author_json = JSON.parse(File.read(AUTHOR_INDEX_FILE))
  save_author_index author_json, "[BPAN] Rebuild author directory"
  msg = "Successful rebuild of indexes and webpage"
  LOG.info msg
  return msg
end

def add_author data
  author = data['sender']
  login = author['login']
  LOG.debug "Received star from #{login}"
  index = JSON.parse File.open(AUTHOR_INDEX_FILE, "r:UTF-8", &:read)
  index[login] = format_author(author)
  save_author_index index, "[BPAN] Add author #{login}"
  return "Added author #{login}"
end

def add_package data
  return if data['master_branch'].nil?
  LOG.debug "Tag %s created on %s" % [
    data['ref'].inspect,
    data['repository']['clone_url'].inspect,
  ]
  meta = nil
  sha1 = nil
  Dir.mktmpdir('bpan_package_clone') do |dir|
    url = data['repository']['clone_url']
    tag = data['ref']
    git = Git.clone(url, tag, path: dir, log: LOG, depth: 0)
    git.checkout tag
    sha1 = git.revparse tag
    meta = YAML.safe_load(File.read(File.join(dir, tag, 'Meta')))
  end

  repo = data['repository']['clone_url'].sub(/.*\//, '').sub(/\.git$/, '')
  name = meta['name']
  owner = data['repository']['owner']['login']
  version = meta['version']
  full_name = "#{name}/#{owner}"
  full_key = "#{full_name}/#{version}"

  meta_dir = File.join META_DIR, name
  Dir.mkdir(meta_dir) unless Dir.exists? meta_dir
  meta_file = File.join meta_dir, "#{owner},#{version}"
  File.open(meta_file, 'w') {|f| f.write JSON.pretty_generate meta}

  index = JSON.parse File.open(PACKAGE_INDEX_FILE, "r:UTF-8", &:read)
  index[name] ||= full_name
  if versions = index[full_name]
    index[full_name] = "#{version} #{versions}"
  else
    index[full_name] = version
  end
  index[full_key] = "#{sha1} #{Time.now.to_i} GitHub #{owner} #{repo}"

  save_package_index index, "[BPAN] Add package #{full_key}"

  return "Pushed %s version %s sha %s" % [ full_name, version, sha1 ]
end

def save_package_index index, message
  # Regenerate json index. Pretty printed and top keys sorted.
  json = JSON.pretty_generate Hash[ index.keys.sort.map{|k|[k,index[k]]} ]
  File.open(PACKAGE_INDEX_FILE, 'w') {|f| f.write json}
  GIT.add(INDEX_DIR)
  begin
    GIT.commit(message)
    GIT.push 'origin', GH_PAGES_BRANCH
  rescue Git::GitExecuteError => e
    raise e unless e.message =~ /nothing to commit/i
  end
end

def save_author_index index, message
  json = JSON.pretty_generate Hash[ index.keys.sort.map{|k|[k,index[k]]} ]
  File.open(AUTHOR_INDEX_FILE, 'w') {|f| f.write json}
  GIT.add(AUTHOR_INDEX_FILE)

  # Regenerate homepage
  `(cd gh-pages/_cogweb; make site)`
  GIT.add(File.basename(HOMEPAGE_FILE))

  # Regenerate json index
  begin
    GIT.commit(message)
    GIT.push 'origin', GH_PAGES_BRANCH
  rescue Git::GitExecuteError => e
    raise e unless e.message =~ /nothing to commit/i
  end
end

def format_author author
  { "github-id" => author['login'],
    "gravatar-id" => author["gravatar_id"],
  }
end
