class EApp
  module Setup

    # set the baseurl for assets.
    # by default, assets URL is empty.
    # 
    # @example assets_url not set
    #   script_tag 'master.js'
    #   => <script src="master.js"
    #   style_tag 'theme.css'
    #   => <link href="theme.css"
    #
    # @example assets_url set to /assets
    #
    #   script_tag 'master.js'
    #   => <script src="/assets/master.js"
    #   style_tag 'theme.css'
    #   => <link href="/assets/theme.css"
    #
    # @note
    #   if second argument given, Espresso will reserve given URL for serving assets,
    #   so make sure it does not interfere with your actions.
    #
    # @example
    #
    # class App < E
    #   map '/'
    #
    #   # actions inside controller are not affected 
    #   # cause app is not set to serve assets, thus no URLs are reserved.
    #   
    # end
    #
    # app = EApp.new do
    #   assets_url '/'
    #   mount App
    # end
    # app.run
    #
    #
    # @example
    #
    # class App < E
    #   map '/'
    #   
    #   # no action here will work cause "/" URL is reserved for assets
    #   
    # end
    #
    # app = EApp.new do
    #   assets_url '/', :serve
    #   mount App
    # end
    # app.run
    #
    # @example
    #
    # class App < E
    #   map '/'
    #  
    #   def assets
    #     # this action wont work cause "/assets" URL is reserved for assets
    #   end
    #
    #   # other actions will work normally
    #  
    # end
    #
    # app = EApp.new do
    #   assets_url '/assets', :serve
    #   mount App
    # end
    # app.run
    #
    def assets_url url = nil, serve = nil
      if url
        assets_url     = rootify_url(url)
        @assets_url    = (assets_url =~ /\/\Z/ ? assets_url : assets_url << '/').freeze
        @assets_server = true if serve
      end
      @assets_url ||= ''
    end
    alias assets_map assets_url

    def assets_server?
      @assets_server
    end

    # used when app is serving assets.
    # by default, Espresso will serve files found under public/ folder inside app root.
    # use `assets_path` at class level to set custom path.
    #
    # @note `assets_path` is used to set paths relative to app root.
    #       to set absolute path to assets, use `assets_fullpath` instead.
    #
    def assets_path path = nil
      @assets_path = root + normalize_path(path).freeze if path
      @assets_path ||= '' << root << 'public/'.freeze
    end

    def assets_fullpath path = nil
      @assets_fullpath = normalize_path(path).freeze if path
      @assets_fullpath
    end

  end
end

class E

  class EspressoFrameworkInstanceVariables

    attr_accessor :assets_proxy

    def assets__opts_to_s opts
      (@assets_opts ||= {})[opts] = opts.keys.inject([]) do |f, k|
        f << '%s="%s"' % [k, @ctrl.escape_html(opts[k])]
      end.join(' ')
    end
  end

  class EspressoFrameworkAssetsProxy

    def initialize ctrl
      @ctrl = ctrl
      @wd   = ''.freeze
    end

    def path
      (fullpath = @ctrl.app.assets_fullpath) ? fullpath : @ctrl.app.assets_path
    end

    def url path = nil
      '' << @ctrl.app.assets_url << @wd << (path||'')
    end

    def chdir path
      path = path.to_s
      return @wd = '' if path == '/'
      wd, path = @wd.split('/'), path.split('/')
      path.each do |c|
        c.empty? && next
        c == '..' && wd.pop && next
        wd << c
      end
      @wd = (wd.size > 0 ? wd.reject { |c| c.empty? }.join('/') << '/' : '').freeze
    end
  end

  def assets
    __e__.assets_proxy ||= EspressoFrameworkAssetsProxy.new(self.class)
  end

  def image_tag src = nil, opts = {}
    src.is_a?(Hash) && (opts = src.dup) && (src = nil)
    opted_src = opts.delete(:src)
    src ||= opted_src || raise('Please provide image URL as first argument or :src option')
    opts[:alt] ||= ::File.basename(src, ::File.extname(src))
    "<img src=\"%s\" %s />\n" % [
        opted_src ? opted_src : assets.url(src),
        __e__.assets__opts_to_s(opts)
      ]
  end

  alias img_tag image_tag

  def script_tag src = nil, opts = {}, &proc
    src.is_a?(Hash) && (opts = src.dup) && (src = nil)
    opts[:type] ||= 'text/javascript'
    if proc
      "<script %s>\n%s\n</script>\n" % [__e__.assets__opts_to_s(opts), proc.call]
    else
      opted_src = opts.delete(:src)
      src ||= opted_src || raise('Please provide script URL as first argument or via :src option')
      "<script src=\"%s\" %s></script>\n" % [
          opted_src ? opted_src : assets.url(src),
          __e__.assets__opts_to_s(opts)
        ]
    end
  end

  def style_tag src = nil, opts = {}, &proc
    src.is_a?(Hash) && (opts = src.dup) && (src = nil)
    if proc
      opts[:type] ||= 'text/css'
      "<style %s>\n%s\n</style>\n" % [__e__.assets__opts_to_s(opts), proc.call]
    else
      opts[:rel] = 'stylesheet'
      opted_src = opts.delete(:href) || opts.delete(:src)
      src ||= opted_src || raise('Please URL as first argument or :href option')
      "<link href=\"%s\" %s />\n" % [
          opted_src ? opted_src : assets.url(src),
          __e__.assets__opts_to_s(opts)
        ]
    end
  end

end
