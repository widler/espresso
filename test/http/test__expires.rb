module EHTTPTest__Expires

  GENERIC_AMOUNT = 600
  GENERIC = [:public, :must_revalidate]

  PRIVATE_AMOUNT = 20
  PRIVATE = [:private, :proxy_revalidate]

  INLINE_AMOUNT = 500
  INLINE = [:no_cache, :no_store]

  XML_AMOUNT = 200
  XML = [:no_store, :must_revalidate]

  class App < E
    format :xml

    expires GENERIC_AMOUNT, *GENERIC

    setup :private do
      expires PRIVATE_AMOUNT, *PRIVATE
    end

    setup '.xml' do
      expires XML_AMOUNT, *XML
    end

    def index

    end

    def private

    end

    def read something

    end

    def inline
      expires! INLINE_AMOUNT, *INLINE
    end

  end

  Spec.new App do

    def contain_suitable_headers? response, amount, *directives
      actual = response.headers.values_at('Cache-Control', 'Expires')
      expected = [
          E.new.cache_control!(*directives << {:max_age => amount}),
          (Time.now + amount).httpdate
      ]
      is?(expected) == actual
    end

    get
    does(last_response).contain_suitable_headers? GENERIC_AMOUNT, *GENERIC

    get :private
    does(last_response).contain_suitable_headers? PRIVATE_AMOUNT, *PRIVATE

    get :inline
    does(last_response).contain_suitable_headers? INLINE_AMOUNT, *INLINE

    get 'index.xml'
    does(last_response).contain_suitable_headers? XML_AMOUNT, *XML

    get :read, 'book.xml'
    does(last_response).contain_suitable_headers? XML_AMOUNT, *XML

  end
end
