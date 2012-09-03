class << E

  def crud resource, *path_or_opts, &proc
    opts = path_or_opts.last.is_a?(Hash) ? path_or_opts.pop : {}
    path = path_or_opts.first
    action = '%s_' << (path || :index).to_s
    resource_method = {
        :get => opts.fetch(:get, :get),
        :post => opts.fetch(:post, :create),
        :put => opts.fetch(:put, :update),
        :patch => opts.fetch(:patch, :update),
        :delete => opts.fetch(:delete, :delete),
    }
    presenter = lambda { |controller_instance, obj| proc ? controller_instance.instance_exec(obj, &proc) : obj }
    fetch_object = lambda do |controller_instance, id|
      resource.send(resource_method[:get], id) ||
          controller_instance.halt(404, 'object with ID %s not found' % controller_instance.escape_html(id))
    end
    update_object = lambda do |controller_instance, request_method, id|
      object = fetch_object.call(controller_instance, id)
      object.send(resource_method[request_method], controller_instance.post_params)
      presenter.call controller_instance, object
    end
    self.class_exec do

      define_method action % :get do |id|
        presenter.call self, fetch_object.call(self, id)
      end

      define_method action % :head do |id|
        presenter.call self, fetch_object.call(self, id)
      end

      define_method action % :post do
        presenter.call self, resource.send(resource_method[:post], post_params)
      end

      define_method action % :put do |id|
        update_object.call self, :put, id
      end

      define_method action % :patch do |id|
        update_object.call self, :patch, id
      end

      # if resource respond to #delete(or whatever set in options for delete),
      # sending #delete to resource, with given id as 1st param.
      # otherwise, fetching object by given id and sending #delete on it.
      #
      # @return [String] empty string
      define_method action % :delete do |id|
        meth = resource_method[:delete]
        if resource.respond_to?(meth)
          resource.send(meth, id)
        elsif object = fetch_object.call(self, id)
          if object.respond_to?(meth)
            object.send meth
          elsif object.respond_to?(:delete!)
            object.send :delete!
          elsif object.respond_to?(:destroy)
            object.send :destroy
          elsif object.respond_to?(:destroy!)
            object.send :destroy!
          else
            halt 500, 'Given object does not respond to any of #%s' % [
              meth, :delete!, :destroy, :destroy!
            ].uniq.join(" #")
          end
        end
        ''
      end

      define_method action % :options do
        ::AppetiteConstants::REQUEST_METHODS.map do |request_method|
          if restriction = self.class.restrictions?((action % request_method.downcase).to_sym)
            auth_class, auth_args, auth_proc = restriction
            auth_class.new(proc {}, *auth_args, &auth_proc).call(env) ? nil : request_method
          else
            request_method
          end
        end.compact.join(', ')
      end

    end

  end

  alias crudify crud

end
