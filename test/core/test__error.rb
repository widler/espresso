module ECoreTest__Error

  class App < E

    error 404 do
      'NoLuckTryAgain'
    end

    error 500 do |e|
      'FatalErrorOccurred: %s' % e
    end

    setup :json do
      error 500 do |e|
        "status:0, error:#{e}"
      end
    end

    def index

    end

    def raise_error
      some risky code
    end

    def json
      blah!
    end

  end

  Spec.new App, :skip => true do

    Testing 404 do
      r = get :blah!
      expect(r.status) == 404
      is?(r.body) == 'NoLuckTryAgain'
    end

    r = get :raise_error
    expect(r.status) == 500
    expect(r.body) =~ /FatalErrorOccurred: undefined local variable or method `code'/

    r = get :json
    expect(r.status) == 500
    expect(r.body) =~ /status\:0, error:undefined method `blah!'/
  end
end
