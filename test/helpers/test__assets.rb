module EHelpersTest__Assets

  class App < E

    def image
      opts = params.inject({}){|o, p| o.update p.first.to_sym => p.last }
      if (image = opts.delete(:image))
        image_tag image, opts
      else
        image_tag opts
      end
    end

  end

  Spec.new self do
    app EApp.new do
      root File.expand_path('..', __FILE__)

    end.mount(App)
    map App.base_url

    get :image, :image => 'image.jpg'
    is(last_response.body) == '<img src="/assets/images/image.jpg" alt="image" />'

    get :image, :src => '/image.jpg'
    is(last_response.body) == '<img src="/image.jpg" alt="image" />'

    get :image, :image => 'image.png', :alt => 'ALTO'
    is(last_response.body) == '<img src="/assets/images/image.png" alt="ALTO" />'

  end
end
