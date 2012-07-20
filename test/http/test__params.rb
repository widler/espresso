module EHTTPTest__Params

  class App < E

    def index
      [get_params['var'], get_params[:var]].join
    end

    def post_index
      [post_params['var'], post_params[:var]].join
    end

    def mixed
      '%s/%s; %s/%s' % [params[:get], params['get'], params[:post], params['post']]
    end


  end

  Spec.new App do

    val = rand.to_s
    r = get :index, :var => val
    expect(r.body) == val + val

    val = rand.to_s
    r = post :index, :var => val
    expect(r.body) == val + val

    r = get :mixed, '?get=get', :post => 'post'
    expect(r.body) == 'get/get; post/post'

  end
end
