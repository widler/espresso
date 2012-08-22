module EViewTest__InnerController
  module App
    class Index < E
      map '/'
      engine :Haml
      layout :master
      layouts_path 'inner-controller/layouts'
      format :html
      
      def index
        render Inner
      end

      def partial
        render_p Inner
      end

      def given template
        render Inner, template
      end

      def given_partial template
        render_p Inner, template
      end

      def inline greeting
        @greeting = greeting
        render Inner do
          "Hello World"
        end
      end

      def inline_partial greeting
        @greeting = greeting
        render_p Inner do
          "Hello World"
        end
      end

      def layout
        render_l Inner do
          "Hello World"
        end
      end

      def given_layout template
        render_l Inner, template do
          "Hello World"
        end
      end

      def custom_layout
        render Inner, :custom_layout
      end


    end

    class Inner < E
      map '/inner-controller'
      engine :ERB
      view_path :templates
      layouts_path 'inner-controller'
      layout :layout

      setup :custom_layout do
        layout :layout_custom
      end

    end
  end

  Spec.new App do
    app EApp.new { root File.expand_path '..', __FILE__ }.mount(App)

    Should 'render current action' do
      get :index
      check(last_response.body) == 'inner layout - index'
      
      get 'index.html'
      check(last_response.body) == 'inner layout - index.html'

      get :partial
      check(last_response.body) == 'partial'
    end
    
    Should 'render given template' do
      get :given, :index
      is?(last_response.body) == 'inner layout - given'
      
      get :given_partial, :partial
      is?(last_response.body) == 'given_partial'
    end

    Testing 'inline rendering' do
      Should 'render with layout' do
        get :inline, :World
        is?(last_response.body) == 'inner layout - Hello World'
      end

      Should 'render without layout' do
        get :inline_partial, :World
        is?(last_response.body) == 'Hello World'
      end
    end

    Testing :render_layout do
      Should 'render the layout of current action' do
        get :layout
        is?(last_response.body) == 'inner layout - Hello World'
      end

      Should 'render given layout' do
        get :given_layout, :layout
        is?(last_response.body) == 'inner layout - Hello World'
      end
    end

    Testing 'custom layout' do
      get :custom_layout
      check(last_response.body) == 'custom layout - custom_layout'
    end

  end
end
