module EViewTest__render_file
  class App < E
    class Sandbox
      attr_reader :params

      def initialize params = {}
        @params = params
      end
    end

    def index greeting
      @greeting = greeting
      render_file 'index'
    end

    def get_layout layout
      render_file layout do
        'World'
      end
    end

    def given file
      render_file file
    end

    def custom_context file, content
      render_file file, Sandbox.new(params[:sandbox_params]) do
        content
      end
    end

    def custom_locals file, content
      render_file file, params do
        content
      end
    end

  end

  Spec.new App do

    r = get 'World'
    is?(r.body) == 'World'

    r = get :Blah!
    is?(r.body) == 'Blah!'

    Should 'render as layout' do
      r = get :layout, :layout
      is?(r.body) == 'Hello World!'

      r = get :layout, 'layout__master'
      is?(r.body) == 'Hello World!'

      r = get :layout, 'layout__custom_context', :foo => 'bar', :sensitive_data => 'Blah!'
      is?(r.body) == 'layout-foo=bar;layout-sensitive_data=Blah!;World'
    end

    Should 'render as regular file' do
      r = get :given, 'some-action'
      is?(r.body) == 'given'
    end

    Should 'keep given extension' do
      is?(get(:given, 'some-file.xhtml').body) == 'given/some-file.xhtml'
    end

    Should 'render within custom context' do
      r = get :custom_context, :layout__custom_context, (content = rand.to_s), :sandbox_params => {'foo' => 'bar'}, :sensitive_data => 'blah!'
      expect(r.body) == 'layout-foo=bar;layout-sensitive_data=;%s' % content
    end
    Should 'render current action with custom locals' do
      r = get :custom_locals, :layout__custom_locals, (content = rand.to_s), 'foo' => 'bar'
      expect(r.body) == 'layout-foo=bar;%s' % content
    end

  end
end
