module EHelpersTest__Assets

  class App < E

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

    def chdir
      out = []
      params[:paths].each do |p|
        assets.chdir p
        out << assets.url
      end
      out.join("\n")
    end

  end

  Spec.new self do
    app = EApp.new do
      root File.expand_path('..', __FILE__)
      assets_url '/'
    end.mount(App)
    app(app)
    map App.base_url

    Testing :chdir do
      map = {
        'vendor'        => '/vendor/',
        'js'            => '/vendor/js/', 
        'jquery'        => '/vendor/js/jquery/', 
        '../bootstrap'  => '/vendor/js/bootstrap/', 
        '../../css'     => '/vendor/css/', 
        'jquery-ui'     => '/vendor/css/jquery-ui/', 
        '/'             => '/'
      }
      get :chdir, :paths => map.keys
      body = last_response.body.split("\n")
      map.keys.each_with_index do |k, i|
        check(body[i]) == map[k]
      end
    end

    Testing :image_tag do

      get :image_with_url, 'image.jpg'
      is(last_response.body) == '<img src="/image.jpg" alt="image" />' << "\n"

      get :image_with_src, 'image.jpg'
      is(last_response.body) == '<img src="image.jpg" alt="image" />' << "\n"
    end

    Testing :script_tag do

      get :script_with_url, 'url.js'
      check(last_response.body) == '<script src="/url.js" type="text/javascript"></script>' << "\n"

      get :script_with_src, 'src.js'
      check(last_response.body) == '<script src="src.js" type="text/javascript"></script>' << "\n"

      get :script_with_block, :some => 'param'
      lines = last_response.body.split("\n").map { |s| s.strip }
      check(lines[0]) == '<script some="param" type="text/javascript">'
      check(lines[1]) == '{"some"=>"param"}'
      check(lines[2]) == '</script>'

    end

    Testing :style_tag do

      get :style_with_url, 'url.css'
      check(last_response.body) == '<link href="/url.css" rel="stylesheet" />' << "\n"

      get :style_with_src, 'src.css'
      check(last_response.body) == '<link href="src.css" rel="stylesheet" />' << "\n"

      get :style_with_block, :some => 'param'
      lines = last_response.body.split("\n").map { |s| s.strip }
      check(lines[0]) == '<style some="param" type="text/css">'
      check(lines[1]) == '{"some"=>"param"}'
      check(lines[2]) == '</style>'

    end
  end
end
