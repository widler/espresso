module ECoreTest__Hooks

  class App < E

    before { @hooks ||= 0; @hooks += 1 }
    before { @hooks ||= 0; @hooks += 1 }
    after { response.body = [@hooks.to_s] }

    setup :index do
      before { @hooks ||= 0; @hooks += 1 }
      before { @hooks ||= 0; @hooks += 1 }
      after { response.body = [@hooks.to_s] }
    end

    setup :post_index do
      before { @hooks ||= 0; @hooks += 1 }
      before { @hooks ||= 0; @hooks += 1 }
      after { response.body = [@hooks.to_s] }
    end

    setup :get_params do
      after do
        body = RUBY_VERSION.to_f == 1.8 ? action_params[0] : action_params[:id]
        response.body = [body]
      end
    end

    format :json
    setup 'index.json' do
      before { @hooks ||= 0; @hooks += 1 }
    end

    def index
    end

    def post_index
    end

    def global
    end

    def wildcard_setup

    end

    def get_params id

    end

  end

  Spec.new App do

    Testing 'hook set for ALL actions' do
      get
      expect(last_response.body) == '4'

      post
      expect(last_response.body) == '4'
    end

    Testing 'hook set for SPECIFIC actions' do
      get :global
      expect(last_response.body) == '2'

      get :params, '100'
      expect(last_response.body) == '100'
    end

    Testing 'hook set for SPECIFIC actions on SPECIFIC format' do
      get
      is?(last_response.body) == '4'
      get 'index.json'
      is?(last_response.body) == '3'
    end
  end

end
