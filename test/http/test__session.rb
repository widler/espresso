module EHTTPTest__Session

  class App < E

    setup :readonly_set_by_hook do
      before { session.readonly! }
    end

    def set var, val
      session[var] = val
    end

    def get var
      session[var] || 'notSet'
    end

    def flash_set var, val
      flash[var] = val
    end

    def flash_get var
      flash[var] || 'notSet'
    end

    def delete var
      session.delete[var]
    end

    def readonly_set_by_hook var, val
      session[var] = val
    end

    def readonly_set_directly var, val
      session.readonly!
      session[var] = val
    end

  end

  Spec.new App do
    app App.mount.setup { session :memory }
    map App.route

    var, val = rand.to_s, rand.to_s
    get :set, var, val

    r = get :get, var
    expect(r.body) =~ /#{val}/

    Test :readonly do

      o 'setting directly'
      var, val = rand.to_s, rand.to_s
      get :readonly_set_directly, var, val
      r = get :get, var
      expect(r.body) =~ /notSet/

      o 'setting via hooks'
      var, val = rand.to_s, rand.to_s
      get :readonly_set_by_hook, var, val
      r = get :get, var
      expect(r.body) =~ /notSet/
    end

    Testing :flash do
      var, val = rand.to_s, rand.to_s
      get :flash_set, var, val

      r = get :flash_get, var
      expect(r.body) =~ /#{val}/

      r = get :flash_get, var
      expect(r.body) =~ /notSet/
    end

  end

end
