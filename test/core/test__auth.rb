module ECoreTest__Auth

  class App < E

    setup :basic, :post_basic do
      auth { |u, p| [u, p] == ['b', 'b'] }
    end

    setup :digest, :post_digest do
      digest_auth { |u| {'d' => 'd'}[u] }
    end

    def basic
      action
    end

    def digest
      action
    end

    def post_basic
      action
    end

    def post_digest
      action
    end
  end

  Spec.new App do

    Testing 'Basic via GET' do
      r = get :basic
      expect(r.status) == 401

      authorize 'b', 'b'

      r = get :basic
      expect(r.status) == 200

      reset_basic_auth!

      r = get :basic
      expect(r.status) == 401
    end

    Testing 'Basic via POST' do
      reset_basic_auth!

      r = post :basic
      expect(r.status) == 401

      authorize 'b', 'b'

      r = post :basic
      expect(r.status) == 200

      reset_basic_auth!

      r = post :basic
      expect(r.status) == 401
    end

    Testing 'Digest via GET' do

      reset_digest_auth!

      r = get :digest
      expect(r.status) == 401

      digest_authorize 'd', 'd'

      r = get :digest
      expect(r.status) == 200

      reset_digest_auth!

      r = get :digest
      expect(r.status) == 401
    end

    Testing 'Digest via POST' do

      reset_digest_auth!

      r = post :digest
      expect(r.status) == 401

      digest_authorize 'd', 'd'

      r = post :digest
      expect(r.status) == 200

      reset_digest_auth!

      r = post :digest
      expect(r.status) == 401
    end
  end

end
