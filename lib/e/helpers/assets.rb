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

  def image_tag *args
    src, opts = nil, {}
    args.each { |a| a.is_a?(Hash) ? opts.update(a) : src = a }
    opts[:src] ||= (src ? ('' << assets_url(:image) << src) : raise('please provide image src as string or :src option'))
    opts[:alt] ||= ::File.basename(opts[:src], ::File.extname(opts[:src]))
    opts = opts.keys.sort.inject([]) { |f, k| f << '%s="%s"' % [k, escape_html(opts[k])] }.join(' ')
    '<img %s />' % opts
  end

end
