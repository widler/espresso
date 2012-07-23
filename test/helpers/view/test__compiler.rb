module EViewTest__Compiler
  class App < E

    before do
      if key = params[:__update_compiler__]
        key == '*' ? update_compiler! : update_compiler!(key)
      end
    end

    layout :layout

    def index file
      unless params[:__update_compiler__]
        render '' => true do
          render_partial file, '' => file
        end
      end
    end

    def threaded file
      unless params[:__update_compiler__]

        o = nil
        Thread.new do
          o = render '' => true do
            render_partial file, '' => file
          end
        end.join
        o
      end
    end

  end

  Spec.new App do

    def file content
      file = rand.to_s
      path = App.view_fullpath? + file +
          (App.engine_ext? || App.engine_default_ext?(App.engine?.first))
      ::File.open(path, 'w') { |f| f << content }
      [file, path]
    end

    file, path = file('World')

    r = get file
    ::File.unlink path
    is?(r.body) == 'Hello World!'

    Should 'return same result after file deleted' do
      expect { ::File.read path }.raise_error

      r = get file
      is?(r.body) == 'Hello World!'
    end

    Should 'clear compiler and raise an error on render' do
      get file, :__update_compiler__ => '*'
      expect { get file }.raise_error
    end

    Should 'behave well on threaded scenarios' do

      file, path = file('World')

      r = get :threaded, file
      ::File.unlink path
      is?(r.body) == 'Hello World!'

      Should 'return same result after file deleted' do
        expect { ::File.read path }.raise_error

        r = get :threaded, file
        is?(r.body) == 'Hello World!'
      end

      Should 'clear compiler and raise an error on render' do
        get :threaded, file, :__update_compiler__ => '*'
        expect { get :threaded, file }.raise_error
      end
    end

  end
end
