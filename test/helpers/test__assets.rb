module EHelpersTest__Assets

  class App < E

    before do
      @opts = params.inject({}) { |o, p| o.update p.first.to_sym => p.last }
    end

    def image
      if (url = @opts.delete(:url))
        image_tag url, @opts
      else
        image_tag @opts
      end
    end

    def javascript
      if (url = @opts.delete(:url))
        script_tag url, @opts
      else
        script_tag @opts do
          params.inspect
        end
      end
    end

  end

  Spec.new self do
    app EApp.new do
      root File.expand_path('..', __FILE__)

    end.mount(App)
    map App.base_url

    Testing :images do
      get :image, :url => 'image.jpg'
      is(last_response.body) == '<img src="/images/image.jpg" alt="image" />'

      get :image, :src => '/image.jpg'
      is(last_response.body) == '<img src="/image.jpg" alt="image" />'

      get :image, :url => 'image.png', :alt => 'ALTO'
      is(last_response.body) == '<img src="/images/image.png" alt="ALTO" />'
    end

    Testing :javascript do
      get :javascript, :url => 'test.js'
      check(last_response.body) == '<script src="/test.js" type="text/javascript"></script>'

      get :javascript, :some => 'param'
      snips = last_response.body.split("\n").map { |s| s.strip }
      check(snips[0]) == '<script some="param" type="text/javascript">'
      check(snips[1]) == '{"some"=>"param"}'
      check(snips[2]) == '</script>'

    end
  end
end
