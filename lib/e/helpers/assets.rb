class EApp
  module Setup

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

    # if your app should serve assets, 
    # use `app#assets_url` to set the URL that will serve assets.
    # @note 
    #   make sure given URL does not interfere with your actions
    def assets_url url = nil
      @assets_url = rootify_url(url).freeze if url
      @assets_url
    end

    def assets_map map = nil
      @assets_map = map if map.is_a?(Hash)
      @assets_map ||= indifferent_params({
         :script => '/',
         :style => '/',
         :image => '/images/',
         :video => '/videos/',
         :audio => '/audios/',
       }).freeze
    end

  end
end

class E

  def assets_path
    (fullpath = self.class.app.assets_fullpath) ? fullpath : self.class.app.assets_path
  end

  def assets_url type = nil
    url = self.class.app.assets_url ? self.class.app.assets_url.dup : ''
    type ? url << self.class.app.assets_map[type] : url
  end

  def image_tag src = nil, opts = {}
    src.is_a?(Hash) && (opts = src) && (src = nil)
    opted_src = opts.delete(:src)
    src ||= opted_src || raise('Please provide image URL as first argument or :src option')
    opts[:alt] ||= ::File.basename(src, ::File.extname(src))
    '<img src="%s" %s />' % [
        opted_src ? opted_src : '' << assets_url(:image) << src,
        __e__.assets__opts_to_s(opts)
      ]
  end

  alias img_tag image_tag

  def script_tag src = nil, opts = {}, &proc
    src.is_a?(Hash) && (opts = src) && (src = nil)
    opts[:type] ||= 'text/javascript'
    if proc
      html = <<HTML
<script %s>
  %s
</script>
HTML
      html % [__e__.assets__opts_to_s(opts), proc.call]
    else
      opted_src = opts.delete(:src)
      src ||= opted_src || raise('Please provide script URL as first argument or :src option')
      '<script src="%s" %s></script>' % [
          opted_src ? opted_src : '' << assets_url(:script) << src,
          __e__.assets__opts_to_s(opts)]
    end
  end

end
