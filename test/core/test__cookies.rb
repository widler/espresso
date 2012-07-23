module ECoreTest__Cookies

  class App < E

    setup :readonly_set_by_hook do
      before { cookies.readonly! }
    end

    def set var, val
      cookies[var] = {:value => val, :path => '/'}
    end

    def get var
      cookies[var]
    end

    def readonly_set_by_hook var, val
      cookies[var] = val
    end

    def readonly_set_directly var, val
      cookies.readonly! unless params[:freedom]
      set var, val
    end
  end

  Spec.new App do

    Testing 'set/get' do
      var, val = 2.times.map { rand.to_s }
      get :set, var, val
      r = get :get, var
      expect(r.body) =~ /#{val}/
    end

    Test :readonly do

      o 'setting directly'
      var, val = 2.times.map { rand.to_s }
      get :readonly_set_directly, var, val
      r = get :get, var
      refute(r.body) =~ /#{val}/

      var, val = 2.times.map { rand.to_s }
      get :readonly_set_directly, var, val, :freedom => 'true'
      r = get :get, var
      expect(r.body) =~ /#{val}/

      o 'setting via hooks'
      var, val = 2.times.map { rand.to_s }
      get :readonly_set_by_hook, var, val
      r = get :get, var
      refute(r.body) =~ /#{val}/

    end

  end

end
