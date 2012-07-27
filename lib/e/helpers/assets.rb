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

    def assets_url url = nil
      @assets_url = rootify_url(url).freeze if url
      @assets_url ||= '/assets'.freeze
    end

    def assets_map map = nil
      @assets_map = map if map.is_a?(Hash)
      @assets_map ||= indifferent_params({
                                            :image => 'images/',
                                            :css => 'styles/',
                                            :js => 'scripts/',
                                            :video => 'videos/',
                                            :audio => 'audios/',
                                        }).freeze
    end

  end
end

class E

  def assets_path
    (fullpath = self.class.app.assets_fullpath) ? fullpath : self.class.app.assets_path
  end

  def assets_url type = nil
    url = self.class.app.assets_url.dup
    type ? url << '/' << self.class.app.assets_map[type] : url
  end

  def image_tag src = nil, opts = {}
    src.is_a?(Hash) && (opts = src) && (src = nil)
    opted_src = opts.delete(:src)
    src ||=  opted_src || raise('Please provide image URL as first argument or :src option')
    opts[:alt] ||= ::File.basename(src, ::File.extname(src))
    '<img src="%s" %s />' % [
        opted_src ? opted_src : '' << assets_url(:image) << src,
        opts.keys.inject([]) { |f, k| f << '%s="%s"' % [k, escape_html(opts[k])] }.join(' ')]
  end

end
