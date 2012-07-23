module ECoreTest__Stream

  class App < E

    content_type '.txt'

    def get_stream
      stream do |s|
        s << 'a:%s/' % params[:a]
        s << 'c:%s/' % params[:b]
        s << 'c:%s' % params[:c]
      end
    end

  end

  Spec.new App do

    get :stream, :a => '1', :b => '2'
    check(last_response.headers['Content-Type']) == AppetiteHelpers.mime_type('.txt')
    check(last_response.headers['Content-Length']) == '10'
    check(last_response.body) == 'a:1/c:2/c:'

  end
end
