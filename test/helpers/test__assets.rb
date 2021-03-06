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

    def post_load_assets
      load_assets *params[:assets] << {:from => params[:from]}
    end

  end

  Spec.new self do
    app = EApp.new do
      assets_url '/assets'
    end.mount(App)
    app(app)
    map App.base_url


    Testing :image_tag do

      get :image_with_url, 'image.jpg'
      is(last_response.body) == '<img src="/assets/image.jpg" alt="image" />' << "\n"

      get :image_with_src, 'image.jpg'
      is(last_response.body) == '<img src="image.jpg" alt="image" />' << "\n"
    end

    Testing :script_tag do

      get :script_with_url, 'url.js'
      check(last_response.body) == '<script src="/assets/url.js" type="text/javascript"></script>' << "\n"

      get :script_with_src, 'src.js'
      check(last_response.body) == '<script src="src.js" type="text/javascript"></script>' << "\n"

      get :script_with_block, :some => 'param'
      lines = last_response.body.split("\n").map { |s| s.strip }
      check(lines[0]) =~ /some="param"/
      check(lines[0]) =~ /type="text\/javascript"/
      check(lines[1]) == '{"some"=>"param"}'
      check(lines[2]) == '</script>'
    end

    Testing :style_tag do

      get :style_with_url, 'url.css'
      check(last_response.body) == '<link href="/assets/url.css" rel="stylesheet" />' << "\n"

      get :style_with_src, 'src.css'
      check(last_response.body) == '<link href="src.css" rel="stylesheet" />' << "\n"

      get :style_with_block, :some => 'param'
      lines = last_response.body.split("\n").map { |s| s.strip }
      check(lines[0]) =~ /some="param"/
      check(lines[0]) =~ /type="text\/css"/
      check(lines[1]) == '{"some"=>"param"}'
      check(lines[2]) == '</style>'
    end

    Testing :load_assets do

      post :load_assets, :assets => ['master.js', 'styles.css']
      is(last_response.body) == '<script src="/assets/master.js" type="text/javascript"></script>
<link href="/assets/styles.css" rel="stylesheet" />
'
 
      post :load_assets, :assets => ['jquery.js', 'reset.css', 'bootstrap/js/bootstrap.js'], 
        :from => 'vendor/'
      is(last_response.body) == '<script src="/assets/vendor/jquery.js" type="text/javascript"></script>
<link href="/assets/vendor/reset.css" rel="stylesheet" />
<script src="/assets/vendor/bootstrap/js/bootstrap.js" type="text/javascript"></script>
'
 
      Ensure 'path not mapped when it is starting with a slash or protocol' do
        post :load_assets, :assets => ['jquery.js', 'reset.css', 'bootstrap/js/bootstrap.js'], 
          :from => '/vendor/'
        is(last_response.body) == '<script src="/vendor/jquery.js" type="text/javascript"></script>
<link href="/vendor/reset.css" rel="stylesheet" />
<script src="/vendor/bootstrap/js/bootstrap.js" type="text/javascript"></script>
'

        post :load_assets, :assets => ['jquery.js', 'blah/doh.js', 'styles.css'], 
          :from => 'http://cdn.mysite.com/'
        is(last_response.body) == '<script src="http://cdn.mysite.com/jquery.js" type="text/javascript"></script>
<script src="http://cdn.mysite.com/blah/doh.js" type="text/javascript"></script>
<link href="http://cdn.mysite.com/styles.css" rel="stylesheet" />
'     
      end
    end
  end
end
