module EViewTest__Relpath
  class App < E
    map '/'

    view_path :templates
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

    def get_render_file file
      render_file file
    end

  end

  Spec.new App do

    get
    expect(last_response.body) == "Hello World!"

    get :blah
    expect(last_response.body) == "Hello blah.erb - blah!"

    get :given_action, :blah
    expect(last_response.body) == "Hello blah.erb - given_action!"

    get :given_tpl, :partial
    expect(last_response.body) == "Hello get_partial!"

    get :render_layout_action, :get_render_layout_action
    expect(last_response.body) == "format-less layout/get_render_layout_action"

    get :render_layout_file, :layout__format
    expect(last_response.body) == "format-less layout/layout__format"

    get :render_file, 'custom_locals.erb', :foo => 'bar'
    expect(last_response.body) == "foo=bar"

  end
end
