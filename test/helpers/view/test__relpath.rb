module EViewTest__Relpath
  class App < E
    map '/'

    view_path :templates
    view_fullpath false
    layout :layout

    setup :get_render_layout_action do
      layout :layout__format
    end


    def index
      @greeting = 'World'
      render
    end

    def blah
      render
    end

    def given_action action
      render action.to_sym
    end

    def given_tpl tpl
      render tpl
    end

    def get_render_layout_action action
      render_layout action.to_sym do
        action
      end
    end

    def get_render_layout_file file
      render_layout file do
        file
      end
    end

  end

  Spec.new self do
    app EApp.new { root File.expand_path '..', __FILE__ }.mount(App)

    get
    expect(last_response.body) == "Hello World!"

    get :blah
    expect(last_response.body) == "Hello blah.erb - blah!"

    get :given_action, :blah
    expect(last_response.body) == "Hello blah.erb - given_action!"

    get :given_tpl, :partial
    expect(last_response.body) == "Hello partial!"

    get :render_layout_action, :get_render_layout_action
    expect(last_response.body) == "format-less layout/get_render_layout_action"

    get :render_layout_file, :layout__format
    expect(last_response.body) == "format-less layout/layout__format"

  end
end
