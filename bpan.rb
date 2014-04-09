require 'sinatra'
require 'json'
require 'logger'

$stdout.sync = true
logger = Logger.new $stdout

post '/star/?' do
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  logger.debug data.inspect
end

post '/push/?' do
  'push'
end

get '/?' do
  'Welcome to BPAN'
end

def update
  #packages.json
  #authors.json
  #README  
end
