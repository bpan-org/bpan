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
