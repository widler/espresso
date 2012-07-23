module ECoreTest__File

  class App < E

    def inline
      send_file __FILE__
    end

    def attach
      attachment __FILE__
    end

  end

  Spec.new App do

    Test :inline do

      response = get :inline
      is(response.body) =~ /module ECoreTest__File/

    end

    Test :attachment do
      response = get :attach
      is(response.headers['Content-Disposition']) ==
                   'attachment; filename="%s"' % File.basename(__FILE__)
    end

  end
end
