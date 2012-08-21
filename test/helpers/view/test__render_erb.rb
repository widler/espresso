module EViewTest__RenderERB
  class App < E
    map '/adhoc'
    layout :master
    layouts_path 'adhoc/layouts'
    format :html

    def index
      render_erb
    end

    def partial
      render_erb_p
    end

    def given template
      render_erb template
    end

    def given_partial template
      render_erb_p template
    end

    def inline greeting
      @greeting = greeting
      render_erb do
        "Hello <%= @greeting %>"
      end
    end

    def inline_partial greeting
      @greeting = greeting
      render_erb_p do
        "Hello <%= @greeting %>"
      end
    end

    def layout template
      render_erb_l template do
        @template = template
        render_erb_p { "Hello <%= @template %>" }
      end
    end



  end

  Spec.new App do

    Testing 'current action' do
      Should 'render with layout' do
        get
        is?(last_response.body) == 'master layout - index'
        
        get 'index.html'
        is?(last_response.body) == 'master layout - index.html'
      end

      Should 'render without layout' do
        get :partial
        is?(last_response.body) == 'partial'
        
        get 'partial.html'
        is?(last_response.body) == 'partial.html'
      end
    end

    Testing 'given template' do
      Should 'render with layout' do
        get :given, :index
        is?(last_response.body) == 'master layout - given'
        
        get 'given.html', :partial
        is?(last_response.body) == 'master layout - given.html'
      end

      Should 'render without layout' do
        get :given_partial, :partial
        is?(last_response.body) == 'given_partial'
        
        get 'given_partial.html', :index
        is?(last_response.body) == 'given_partial.html'
      end
    end

    Testing 'inline rendering' do
      Should 'render with layout' do
        get :inline, :World
        is?(last_response.body) == 'master layout - Hello World'
      end

      Should 'render without layout' do
        get :inline_partial, :World
        is?(last_response.body) == 'Hello World'
      end
    end

    Testing :render_layout do
      get :layout, :master
      is?(last_response.body) == 'master layout - Hello master'
    end

  end
end
