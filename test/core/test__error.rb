module ECoreTest__Error

  class App < E

    error 404 do
      'NoLuckTryAgain'
    end

    def index

    end

    error 500 do |e|
      'FatalErrorOccurred: %s' % e
    end

    def raise_error
      some risky code
    end

  end

  Spec.new App do

    Testing 404 do
      r = get :blah!
      expect(r.status) == 404
      is?(r.body) == 'NoLuckTryAgain'
    end

    r = get :raise_error
    expect(r.status) == 500
    expect(r.body) =~ /FatalErrorOccurred: undefined local variable or method `code'/
  end
end
