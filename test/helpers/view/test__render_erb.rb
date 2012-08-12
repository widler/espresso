module EViewTest__render_erb
  class App < E
    map '/'
    
    format :xml

    def index greeting
      @greeting = greeting
      render_erb __method__.to_s
    end
    
    def blah
      render_erb
    end

    def get_layout layout
      render_erb layout do
        'World'
      end
    end

    def given file
      render_erb file
    end

    def inline
      render_erb do
        <<-HTML
        Hello <%= params[:greeting] %>!
        HTML
      end
    end

  end

  Spec.new App do

    r = get 'World'
    is?(r.body) == 'World'

    r = get :Blah!
    is?(r.body) == 'Blah!'
    
    Should :render_current_action do
      get :blah
      expect(last_response.body) == "blah.erb - blah"
      
      Should 'use extension even when action used with format' do
        get "blah.xml"
        expect(last_response.body) == "blah.xml.erb"
      end
    end

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

    expect { get(:inline, :greeting => 'World').body.strip } == 'Hello World!'

  end
end
