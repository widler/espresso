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
    expect(last_response.body) == '<img alt="image" src="/assets/images/image.jpg" />'

    get :image, :src => '/image.jpg'
    expect(last_response.body) == '<img alt="image" src="/image.jpg" />'


    get :image, :image => 'image.png', :alt => 'ALTO'
    expect(last_response.body) == '<img alt="ALTO" src="/assets/images/image.png" />'


  end
end
