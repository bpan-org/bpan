require 'sinatra'
require 'json'

post '/star/?' do
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  data.inspect
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
