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
    @view__engine_ext[action] || @view__engine_ext[:*] || engine_default_ext?(engine?(action).first)
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
    view_path!(path, :keep_existing)
  end

  def view_path! path, keep_existing = false
    return if locked? || (@view__path == false && keep_existing)
    path = normalize_path(path.to_s << '/').sub(/\/+\Z/, '/')
    path =~ /\A\// ? 
      view_fullpath!(path, keep_existing) : 
      @view__path = path.freeze
  end

  def view_path?
    @view__deducted_path ||= (p = view_fullpath?) ? p : ('' << app.root << (@view__path || 'view/')).freeze
  end

  def view_fullpath path
    view_fullpath!(path, :keep_existing)
  end

  def view_fullpath! path, keep_existing = false
    return if locked? || (@view__fullpath == false && keep_existing)
    @view__fullpath = path ? normalize_path(path.to_s << '/').sub(/\/+\Z/, '/').freeze : path
  end

  def view_fullpath?
    @view__fullpath
  end

  # set custom path for layouts.
  # default value: view path
  # @note should be relative to view path
  def layouts_path path
    layouts_path!(path, :keep_existing)
  end

  def layouts_path! path, keep_existing = false
    return if locked? || (@view__layouts_path == false && keep_existing)
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
    compiler_pool! pool, true
  end

  def compiler_pool! pool, keep_existing = nil
    return if locked?
    return if @compiler__pool && keep_existing
    @compiler__pool = pool
  end

  def compiler_pool?
    @compiler__pool ||= Hash.new
  end
end

class E

  def render *args, &proc
    controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
    engine_class, engine_opts = controller.engine?(action_or_template)
    engine_args = proc ? [engine_opts] : [__e__template(controller, action_or_template), engine_opts]
    output = __e__engine_instance(compiler_key, engine_class, *engine_args, &proc).render(scope, locals)

    # looking for layout of given action
    # or the one of current action
    layout, layout_proc = controller.layout?(controller[action_or_template] ? action_or_template : action_with_format)
    return output unless layout || layout_proc

    engine_args = layout_proc ? [engine_opts] : [__e__layout_template(controller, layout, controller.engine_ext?(action_or_template)), engine_opts]
    __e__engine_instance(compiler_key, engine_class, *engine_args, &layout_proc).render(scope, locals) { output }
  end

  def render_partial *args, &proc
    controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
    engine_class, engine_opts = controller.engine?(action_or_template)
    engine_args = proc ? [engine_opts] : [__e__template(controller, action_or_template), engine_opts]
    __e__engine_instance(compiler_key, engine_class, *engine_args, &proc).render(scope, locals)
  end
  alias render_p render_partial

  def render_layout *args, &proc
    controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
    engine_class, engine_opts = controller.engine?(action_or_template)
    # render layout of given action
    # or use given action_or_template as template name
    layout, layout_proc = controller[action_or_template] ? controller.layout?(action_or_template) : action_or_template.to_s
    layout || layout_proc || raise('seems there are no layout defined for %s#%s action' % [controller, action_or_template])
    engine_args = layout_proc ? [engine_opts] : [__e__layout_template(controller, layout, controller.engine_ext?(action_or_template)), engine_opts]
    __e__engine_instance(compiler_key, engine_class, *engine_args, &layout_proc).render(scope, locals, &(proc || proc() { '' }))
  end
  alias render_l render_layout

  ::Tilt.mappings.inject({}) do |map, s|
    s.last.each { |e| map.update e.to_s.split('::').last.sub(/Template\Z/, '').downcase => e }
    map
  end.each_pair do |suffix, engine|

    # this can be easily done via `define_method`,
    # however, ruby 1.8 does not support default params for procs
    # TODO: use `define_method` when 1.8 support dropped.
    class_eval <<-RUBY

    def render_#{suffix} *args, &proc
      controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
      engine_args = proc ? [] : [__e__template(controller, action_or_template, '.#{suffix}')]
      output = __e__engine_instance(compiler_key, #{engine}, *engine_args, &proc).render(scope, locals)

      # looking for layout of given action
      # or the one of current action
      layout, layout_proc = controller.layout?(controller[action_or_template] ? action_or_template : action_with_format)
      return output unless layout || layout_proc

      engine_args = layout_proc ? [] : [__e__layout_template(controller, layout, '.#{suffix}')]
      __e__engine_instance(compiler_key, #{engine}, *engine_args, &layout_proc).render(scope, locals) { output }
    end

    def render_#{suffix}_partial *args, &proc
      controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
      engine_args = proc ? [] : [__e__template(controller, action_or_template, '.#{suffix}')]
      __e__engine_instance(compiler_key, #{engine}, *engine_args, &proc).render(scope, locals)
    end
    alias render_#{suffix}_p render_#{suffix}_partial

    def render_#{suffix}_layout *args, &proc
      controller, action_or_template, scope, locals, compiler_key = __e__engine_params(*args)
      # render layout of given action
      # or use given action_or_template as template name
      layout, layout_proc = controller[action_or_template] ? controller.layout?(action_or_template) : action_or_template.to_s
      layout || layout_proc || raise('seems there are no layout defined for %s#%s action' % [controller, action_or_template])
      engine_args = layout_proc ? [] : [__e__layout_template(controller, layout, '.#{suffix}')]
      __e__engine_instance(compiler_key, #{engine}, *engine_args, &layout_proc).render(scope, locals, &(proc || proc() { '' }))
    end
    alias render_#{suffix}_l render_#{suffix}_layout
      
    RUBY

  end

  def compiler_pool
    self.class.compiler_pool?
  end

  # call `clear_compiler!` without args to update all compiled templates.
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
  #          clear_compiler! :banners, :ads
  #        end
  #        if 'some another condition occurred'
  #          # update all templates
  #          clear_compiler!
  #        end
  #      end
  #    end
  #
  # @note using of non-unique keys will lead to templates clashing
  #
  def clear_compiler! *keys
    keys.size == 0 ?
        compiler_pool.clear :
        keys.each do |key|
          compiler_pool.keys.each { |k| k.first == key && compiler_pool.delete(k) }
        end
  end

  # clear compiler of keys that matching given regexp(s) or array(s).
  # if regexp given it will match only String and Symbol keys.
  # if array given it will match only Array keys.
  def clear_compiler_like! *keys
    keys.each do |key|
      if key.is_a? Array
        compiler_pool.keys.each do |k|
          ekey = k.first
          ekey.is_a?(Array) &&
            ekey.size >= key.size &&
            ekey.slice(0, key.size) == key &&
            compiler_pool.delete(k)
        end
      elsif key.is_a? Regexp
        compiler_pool.keys.each do |k|
          ekey = k.first
          (
            (ekey.is_a?(String) && ekey =~ key) ||
            (ekey.is_a?(Symbol) && ekey.to_s =~ key)
          ) && compiler_pool.delete(k)
        end
      else
        raise "#%s only accepts arrays and regexps" % __method__
      end
    end
  end

  # see (#clear_cache_if!)
  def clear_compiler_if! &proc
    compiler_pool.keys.each do |k|
      proc.call(k.first) && compiler_pool.delete(k)
    end
  end

  private

  def __e__engine_params *args
    controller, action_or_template, scope, locals = self.class, action_with_format, self, {}
    args.compact.each do |arg|
      case
        when ::AppetiteUtils.is_app?(arg)
          controller = arg
        when arg.is_a?(Symbol), arg.is_a?(String)
          action_or_template = arg
        when arg.is_a?(Hash)
          locals = arg
        else
          scope = arg
      end
    end
    compiler_key = locals.delete ''
    [controller, action_or_template, scope, locals, compiler_key]
  end

  def __e__engine_instance compiler_key, engine, *args, &proc
    return engine.new(*args, &proc) unless compiler_key
    compiler_pool[ [compiler_key, engine, args, proc] ] ||= engine.new(*args, &proc)
  end

  def __e__template controller, action_or_template, ext = nil
    '' << controller.view_path?  <<                        # controller's path to templates
      controller.base_url << '/' <<                        # controller's route
      action_or_template.to_s <<                           # given template
      (ext || controller.engine_ext?(action_or_template))  # given or deducted extension
  end

  def __e__layout_template controller, layout, ext
    '' << controller.view_path? <<     # controller's path to templates
      controller.layouts_path?  <<     # controller's path to layouts
      layout <<                        # given template
      (ext || '')                      # given or deducted extension
  end

end
