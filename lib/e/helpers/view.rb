class << E

  # @example - use Haml for all actions
  #    engine :Haml
  #
  # @example - use Haml only for :news and :articles actions
  #    class App < E
  #      # ...
  #      setup :news, :articles do
  #        engine :Haml
  #      end
  #    end
  #
  # @example engine with opts
  #    engine :Haml, :some_engine_argument, some_option: 'some value'
  #
  # @param [Symbol] engine
  #   accepts any of Tilt supported engine
  # @param [String] *args
  #   any args to be passed to engine at initialization
  def engine engine, *engine_args
    engine! engine, *engine_args << true
  end

  def engine! engine, *engine_args
    return if locked?
    engine?
    keep_existing = engine_args.delete(true)
    setup__actions.each do |action|
      next if @view__engine[action] && keep_existing

      engine_class = ::Tilt.const_get("#{engine}Template".to_sym)
      engine_opts = engine_args.inject({}) do |args, a|
        a.is_a?(Hash) ? args.merge(a) : args.merge(a => true)
      end.freeze
      @view__engine[action] = [engine_class, engine_opts]
    end
  end

  def engine? action = nil
    @view__engine ||= {}
    @view__engine[action] || @view__engine[:*] || [::Tilt::ERBTemplate, {}]
  end

  # set the extension used by templates
  def engine_ext ext
    engine_ext! ext, true
  end

  def engine_ext! ext, keep_existing = false
    return if locked?
    engine_ext?
    setup__actions.each do |a|
      next if @view__engine_ext[a] && keep_existing
      @view__engine_ext[a] = (normalized_ext ||= normalize_path('.' << ext.to_s.sub(/\A\./, '')).freeze)
    end
  end

  def engine_ext? action = nil
    @view__engine_ext ||= {}
    @view__engine_ext[action] || @view__engine_ext[:*]
  end

  engine_default_ext = ::Tilt.mappings.sort { |a, b| b.first.size <=> a.first.size }.
      inject({}) { |m, i| i.last.each { |e| m.update e => '.' << i.first }; m }
  define_method :engine_default_ext? do |engine|
    engine_default_ext[engine]
  end

  # set the layout to be used by some or all actions.
  #
  # @note
  #   by default no layout will be rendered.
  #   if you need layout, use `layout` to set it.
  #
  # @example set :master layout for :index and :register actions
  #
  #    class Example < E
  #      # ...
  #      setup :index, :register do
  #        layout :master
  #      end
  #    end
  #
  # @example instruct :plain and :json actions to not use layout
  #
  #    class Example < E
  #      # ...
  #      setup :plain, :json do
  #        layout false
  #      end
  #    end
  #
  # @example use a block for layout
  #
  #    class Example < E
  #      # ...
  #      layout do
  #        <<-HTML
  #            header
  #            <%= yield %>
  #            footer
  #        HTML
  #      end
  #    end
  #
  # @param layout
  # @param [Proc] &proc
  def layout layout = nil, &proc
    layout! layout, true, &proc
  end

  def layout! layout = nil, keep_existing = false, &proc
    return if locked?
    layout?
    layout = normalize_path(layout.to_s).freeze unless layout == false
    setup__actions.each do |a|
      next if @view__layout[a] && keep_existing

      # if action provided with format, adding given format to layout name
      if layout && a.is_a?(String) && (format = ::File.extname(a)).size > 0
        layout = layout + format
      end
      @view__layout[a] = [layout, proc]
    end
  end

  def layout? action = nil
    @view__layout ||= {}
    @view__layout[action] || @view__layout[:*]
  end

  # set custom path for templates.
  # default value: app_root/view/
  def view_path path
    @view__path || view_path!(path)
  end

  def view_path! path
    return if locked?
    path = normalize_path(path.to_s << '/').sub(/\/+\Z/, '/')
    path =~ /\A\// ? view_fullpath!(path) : @view__path = path.freeze
  end

  def view_path?
    @view__path ||= 'view/'.freeze
  end

  def view_fullpath path
    view_fullpath!(path)
  end

  def view_fullpath! path
    return if locked?
    @view__fullpath = normalize_path(path.to_s << '/').sub(/\/+\Z/, '/').freeze
  end

  def view_fullpath?
    @view__fullpath
  end

  # set custom path for layouts.
  # default value: view path
  # @note should be relative to view path
  def layouts_path path
    @view__layouts_path || layouts_path!(path)
  end

  def layouts_path! path
    return if locked?
    @view__layouts_path = normalize_path(path.to_s << '/').freeze
  end

  def layouts_path?
    @view__layouts_path ||= ''.freeze
  end

  # for most apps, most expensive operations are fs operations and template compilation.
  # to avoid these operations compiled templates are stored into memory
  # and just rendered on consequent requests.
  #
  # by default, compiled templates are kept in memory.
  #
  # if you want to use a different pool, set it by using `compiler_pool` at class level.
  # make sure your pool behaves just like a Hash,
  # meant it responds to `[]=`, `[]`, `delete`, `delete_if` and `clear` methods.
  # also, the pool SHOULD accept ARRAYS as keys.
  def compiler_pool pool
    @compiler__pool || compiler_pool!(pool)
  end

  def compiler_pool! pool
    return if locked?
    @compiler__pool = pool
  end

  def compiler_pool?
    @compiler__pool ||= Hash.new
  end
end

class E

  def engine action = nil
    self.class.engine?(action || action_with_format)
  end

  def engine_ext action = nil
    self.class.engine_ext?(action || action_with_format) ||
        self.class.engine_default_ext?(engine(action).first)
  end

  def layout action = nil
    self.class.layout?(action || action_with_format)
  end

  def view_path
    self.class.view_path?
  end

  def view_fullpath
    self.class.view_fullpath?
  end

  def layouts_path
    self.class.layouts_path?
  end

  def render *args, &proc
    action, scope, locals, compiler_key = __e__.render_params(*args)
    engine_class, engine_opts = engine action
    engine_args = proc ? [engine_opts] : [__e__.template(action), engine_opts]
    output = __e__.engine(compiler_key, engine_class, *engine_args, &proc).render scope, locals

    layout, layout_proc = __e__.layout_template(self[action] ? action : action())
    return output unless layout || layout_proc

    engine_args = layout_proc ? [engine_opts] : [layout, engine_opts]
    __e__.engine(compiler_key, engine_class, *engine_args, &layout_proc).render(scope, locals) { output }
  end

  def render_partial *args, &proc
    action, scope, locals, compiler_key = __e__.render_params(*args)
    engine_class, engine_opts = engine action
    engine_args = proc ? [engine_opts] : [__e__.template(action), engine_opts]
    __e__.engine(compiler_key, engine_class, *engine_args, &proc).render scope, locals
  end

  def render_layout *args, &proc
    action, scope, locals, compiler_key = __e__.render_params(*args)
    engine_class, engine_opts = engine action
    layout, layout_proc = __e__.layout_template action
    layout || layout_proc || raise('seems there are no layout defined for %s#%s action' % [self.class, action])
    engine_args = layout_proc ? [engine_opts] : [layout, engine_opts]
    __e__.engine(compiler_key, engine_class, *engine_args, &layout_proc).render(scope, locals, &(proc || proc() { '' }))
  end

  def render_file file, scope = nil, locals = nil, &proc
    file, scope, locals, compiler_key = __e__.render_params(file, scope, locals)
    ::File.extname(file).size == 0 && file << engine_ext(action_with_format)
    path = view_fullpath ? '' << view_fullpath : '' << app_root << view_path
    engine_class, engine_opts = engine(action_with_format)
    __e__.engine(compiler_key, engine_class, path << file, engine_opts).render(scope, locals, &proc)
  end

  ::Tilt.mappings.inject({}) do |map, s|
    s.last.each { |e| map.update e.to_s.split('::').last.sub(/Template\Z/, '').downcase => e }
    map
  end.each_pair do |suffix, engine|

    # this can be easily done via `define_method`,
    # however, ruby1.8 does not support default params for procs
    class_eval <<-RUBY
      def render_#{suffix} *args, &proc
        file, scope, locals = nil, self, {}
        args.each{ |a| (a.is_a?(String) || a.is_a?(Symbol)) ? (file = a.to_s) : (a.is_a?(Hash) ? locals = a : scope = a) }
        compiler_key = locals.delete('')
        return __e__.engine(compiler_key, #{engine}, &proc).render(scope, locals) unless file

        ::File.extname(file).size == 0 && file << '.#{suffix}'
        path = view_fullpath ? '' << view_fullpath : '' << app_root << view_path
        __e__.engine(compiler_key, #{engine}, path << file).render(scope, locals, &proc)
      end
    RUBY

  end

  def compiler_pool
    self.class.compiler_pool?
  end

  # call `update_compiler!` without args to update all compiled templates.
  # to update only specific templates pass as arguments the IDs you used to enable compiler.
  #
  # @example
  #    class App < E
  #
  #      def index
  #        @banners = render_view :banners, '' => :banners
  #        @ads = render_view :ads, '' => :ads
  #        render '' => true
  #      end
  #
  #      before do
  #        if 'some condition occurred'
  #          # updating only @banners and @ads
  #          update_compiler! :banners, :ads
  #        end
  #        if 'some another condition occurred'
  #          # update all templates
  #          update_compiler!
  #        end
  #      end
  #    end
  #
  # @note using of non-unique keys will lead to templates clashing
  #
  def update_compiler! *keys
    __e__.sync do
      keys.size == 0 ?
          compiler_pool.clear :
          keys.each { |key| compiler_pool.delete_if { |k, v| k.first == key } }
    end
  end
end
