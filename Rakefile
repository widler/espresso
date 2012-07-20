require 'rubygems'
require 'rake'

task :default => :test

require './test/setup'

namespace :test do
  task :http do
    ::Dir['./test/http/test__*.rb'].each { |f| require f }
    session = Specular.new
    session.boot { include Motor::Mixin }
    session.before do |app|
      if app && ::MeisterUtils.is_app?(app)
        app.use Rack::Lint
        app(app)
        map app.route
      end
    end
    session.run /EHTTPTest/, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code
  end

  task :view do
    ::Dir['./test/view/test__*.rb'].each { |f| require f }
    session = Specular.new
    session.boot { include Motor::Mixin }
    session.before do |app|
      if app && ::MeisterUtils.is_app?(app)
        app.use Rack::Lint
        # using `absolute_view_path` to be sure tests will work on non-Unix-like too
        app app.mount { absolute_view_path ::File.expand_path('../test/view/templates', __FILE__) }
        map app.route
        get
      end
    end
    session.run /EViewTest/, :trace => true
    puts session.failures if session.failed?
    puts session.summary
    session.exit_code
  end
end

task :test => ['test:http', 'test:view']

task :overhead do
  require './test/overhead/run'
end
