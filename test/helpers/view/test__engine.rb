module EViewTest__Engine
  class App < E
    map '/'

    layout :layout
    engine :Haml

    format :xml, :txt
    setup '.xml' do
      engine :ERB
    end

    setup 'blah.xml' do
      engine :String
    end

    setup 'blah.txt' do
      layout! false
      engine! :String
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

    It "should use engine set earlier by `setup '.xml'`, cause `setup 'blah.xml'` does not use bang method, and earlier setup not overridden" do
      get 'blah.xml'
      expect(last_response.body) == "Hello blah.xml.erb!"
    end

    It "should use String engine cause `setup 'blah.txt'` using bang methods and earlier setup are overridden" do
      expect { get('blah.txt').body } == 'blah.txt.str - blah.txt'
    end

  end
end
