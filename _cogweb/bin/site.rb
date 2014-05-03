#!/usr/bin/env ruby

require 'erb'
require 'json'

def h s
  CGI.escape_html s
end

site_path = ARGV[0] or fail

site_index_html_file = File.join site_path, 'index.html'
site_index_html_view = ERB.new(
  File.read File.join 'view', 'index.html.erb'
)
index_author = File.join site_path, 'index', 'author.json'

File.open(site_index_html_file, 'w') {|f|
  author = JSON.parse File.read index_author
  f.write site_index_html_view.result binding
}
