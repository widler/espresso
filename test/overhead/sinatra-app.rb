require 'sinatra/base'

class App < Sinatra::Base
  get '/' do
    'Hello World!'
  end
end

Rack::Handler::Thin.run App, Port: $*[0].to_i
