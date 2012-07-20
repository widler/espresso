module EViewTest__Engine
  class App < E
    map '/'

    layout :layout
    engine :Haml

    format :xml
    setup '.xml' do
      engine :ERB
    end

    setup 'blah.xml' do
      engine :String
    end

    def index
      @var = 'val'
      render
    end

    def blah
      render
    end

  end

  Spec.new App do

    get
    expect(last_response.body) == "HAML Layout/\nval\n"

    get 'index.xml'
    expect(last_response.body) == 'Hello .xml template!'

    get :blah
    expect(last_response.body) == "HAML Layout/\nblah.haml\n"

    get 'blah.xml'
    expect(last_response.body) == "Hello blah.xml.erb!"

  end
end
