module EHelpersTest__Assets

  class App < E

    before do
      @opts = params.inject({}) { |o, p| o.update p.first.to_sym => p.last }
    end

    def image_with_url url
      image_tag url
    end

    def image_with_src src
      image_tag :src => src
    end

    def script_with_url url
      script_tag url
    end

    def script_with_src src
      script_tag :src => src
    end

    def script_with_block
      script_tag params do
        params.inspect
      end
    end

    def style_with_url url
      style_tag url
    end

    def style_with_src src
      style_tag :src => src
    end

    def style_with_block
      style_tag params do
        params.inspect
      end
    end

  end

  Spec.new self do
    app EApp.new do
      root File.expand_path('..', __FILE__)
    end.mount(App)
    map App.base_url

    Testing :image_tag do

      get :image_with_url, 'image.jpg'
      is(last_response.body) == '<img src="/images/image.jpg" alt="image" />'

      get :image_with_src, 'image.jpg'
      is(last_response.body) == '<img src="image.jpg" alt="image" />'
    end

    Testing :script_tag do

      get :script_with_url, 'url.js'
      check(last_response.body) == '<script src="/url.js" type="text/javascript"></script>'

      get :script_with_src, 'src.js'
      check(last_response.body) == '<script src="src.js" type="text/javascript"></script>'

      get :script_with_block, :some => 'param'
      lines = last_response.body.split("\n").map { |s| s.strip }
      check(lines[0]) == '<script some="param" type="text/javascript">'
      check(lines[1]) == '{"some"=>"param"}'
      check(lines[2]) == '</script>'

    end

    Testing :style_tag do

      get :style_with_url, 'url.css'
      check(last_response.body) == '<link href="/url.css" rel="stylesheet" />'

      get :style_with_src, 'src.css'
      check(last_response.body) == '<link href="src.css" rel="stylesheet" />'

      get :style_with_block, :some => 'param'
      lines = last_response.body.split("\n").map { |s| s.strip }
      check(lines[0]) == '<style some="param" type="text/css">'
      check(lines[1]) == '{"some"=>"param"}'
      check(lines[2]) == '</style>'

    end
  end
end



