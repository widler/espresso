module EViewTest__RenderLayout
  class App < E
    class Sandbox
      attr_reader :params

      def initialize params = {}
        @params = params
      end
    end

    format :html

    setup :index do
      layout :layout
    end

    setup 'index.html' do
      layout :layout__format
    end

    setup :falselayout do
      layout false
    end

    setup /custom_context/ do
      layout :layout__custom_context
    end

    setup /custom_locals/ do
      layout :layout__custom_locals
    end

    setup /\Ainline/ do
      layout { 'Hello <%= yield %>!' }
    end

    def index
      render_layout { 'World' }
    end

    def render_given action
      layout = (f = params[:format]) ? action + f : action.to_sym
      render_layout layout do
        'World'
      end
    end

    def layoutless
      render_layout
    end

    def falselayout
      render_layout
    end

    def custom_context
      render_layout Sandbox.new(params[:sandbox_params])
    end

    def custom_context_given layout
      render_layout layout.to_sym, Sandbox.new(params[:sandbox_params])
    end

    def custom_locals
      render_layout params
    end

    def custom_locals_given layout
      render_layout layout.to_sym, params
    end

    def inline
      render_layout { 'World' }
    end

    def inline_given layout
      render_layout(layout.to_sym) { 'World' }
    end

  end

  Spec.new App do

    Should 'correctly detect layout for current action' do
      When 'called without format' do
        r = get
        is?(r.body) == 'Hello World!'
      end
      And 'with format' do
        r = get 'index.html'
        is?(r.body) == '.html layout/World'
      end
    end
    Should 'correctly detect layout for given action' do
      When 'action given without format' do
        r = get :render_given, :index
        is?(r.body) == 'Hello World!'
      end
      And 'action provided with format' do
        r = get :render_given, 'index.html', :format => '.html'
        is?(r.body) == '.html layout/World'
      end
    end
    Should 'correctly detect layout by given path' do
      r = get :render_given, :layout
      is?(r.body) == 'Hello World!'
    end

    Testing 'inline layout' do
      is?(get(:inline).body) == 'Hello World!'
      is?(get(:inline_given, :inline).body) == 'Hello World!'
    end

    Should 'raise error' do
      When 'action has no layout' do
        expect { get :layoutless }.to_raise_error 'seems there are no layout defined'
      end
      When 'action layout set to false' do
        expect { get :falselayout }.to_raise_error 'seems there are no layout defined'
      end
      When 'given layout does not exists' do
        expect { get :render_given, :Blah! }.to_raise_error Errno::ENOENT
      end
    end

    Should 'render the layout of current action within custom context' do
      r = get :custom_context, :sandbox_params => {'foo' => 'bar'}, :sensitive_data => 'blah!'
      expect(r.body) == 'layout-foo=bar;layout-sensitive_data=;'
    end
    Should 'render the layout of given action within custom context' do
      r = get :custom_context_given, :custom_context, :sandbox_params => {'foo' => 'bar'}, :sensitive_data => 'blah!'
      expect(r.body) == 'layout-foo=bar;layout-sensitive_data=;'
    end

    Should 'render the layout of current action with custom locals' do
      r = get :custom_locals, 'foo' => 'bar'
      expect(r.body) == 'layout-foo=bar;'
    end
    Should 'render the layout of given action with custom locals' do
      r = get :custom_locals_given, :custom_locals, 'foo' => 'bar'
      expect(r.body) == 'layout-foo=bar;'
    end

  end
end
