$:.unshift File.expand_path('../../../lib', __FILE__)
require 'e'

class App < E
  map '/'

  def index
    "Hello World!"
  end
end
App.run server: :Thin, Port: $*[0].to_i
