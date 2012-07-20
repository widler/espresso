require ::File.expand_path('../rails-app/config/environment',  __FILE__)

Rack::Handler::Thin.run RailsApp::Application, Port: $*[0].to_i
