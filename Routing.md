
## Base URL

### Set by Controller

By default, every controller will serve the underscored path of its name.

Ex.: `Forum` will serve "/forum", `LatestNews` will serve "/latest_news" etc.

To change this, use `map`.

`map` allow to set base URL for all actions on current controller.

**Example:** - `News` controller should serve "/news"

```ruby
class News < E

    def index
        # ...
    end

    def edit
        # ...
    end
end
</source>
Now `News` will serve:
*   /news
*   /news/index
*   /news/edit
```

### Set by Slice

However, base URL set by `map` can be prefixed too.<br/>
Slices can set base URL for controllers just like controllers setting it for actions.

**Example:** - Setting base URL for `Posts` and `Users` controllers

```ruby
module Forum

    class Posts < E
        # ...
    end

    class Users < E
        # ...
    end

end

# mounting Forum slice
app = Forum.mount '/forum'

# running app
app.run
```
Now, `Forum` slice will serve all addresses under "/forum"

## Canonicals

### Set by Controller

Lets say you need your `News` controller to serve both "/news" and "/headlines".<br/>
It is easily done by using `map` with multiple params.<br/>
First param will be treated as base URL, any other consequent params - as canonicals.

**Example:**

```ruby
class News < E
    map :news, :headlines

    def index
        # ...
    end
end
```
Now, `News` will serve both "/news" and "/headlines" paths.

### Set by Slice

Canonicals can also be set at slice level.<br/>
For this, simply pass multiple params to `mount` method.<br/>
Each consequent param will be treated as canonical path.

**Example:**

```ruby
module Forum

    class Posts < E
        # ...
    end

    class Users < E
        # ...
    end

end

app = Forum.mount '/forum', '/Forums'
```

Now, `Forum` slice will serve any of:
*   /forum/posts
*   /forum/users
*   /Forums/posts
*   /Forums/users

## Actions

Defining actions in Espresso is as simple as defining methods in Ruby,<br/>
cause actions in Espresso are pure Ruby methods.

**Example:** - Defining 2 actions - :index and :edit

```ruby
class MyController < E

  def index
      # ...
  end

  def edit
      # ...
  end
end
```

Now, `MyController` will serve any of:
*   /
*   /index
*   /edit


## Actions Mapping

Sometime actions should also contain non-alphanumeric chars.<br/>
Most common - hypes, dots and slashes.

To address this, Espresso uses a map to translate action names into HTTP paths.

The default map looks like this:

<pre>
"____"    => "."
"___"     => "-"
"__"      => "/"
</pre>

**Example:**

```ruby
def read____html
    # ...
end
# will serve read.html

def latest___news
    # ...
end
# will serve latest-news

def users__online
    # ...
end
# will serve users/online

```

*Worth to note* that you can define your own rules by using `path_rule` at controller or slice level.

**Example:** - Convert bang methods into .html suffixed paths

```ruby
class MyController < E

    path_rule "!", ".html"

  def news!
      # ...
  end
  # will serve news.html
end
```

**Example:** - Convert methods starting with J_ into .json suffixed paths

```ruby
class MyController < E

    path_rule /\AJ_/, ".json"

    def J_news
      # ...
    end
    # will serve news.json
end
```

## Parametrization

In Espresso, calling HTTP actions are the same as calling Ruby methods.

If the Ruby method backing the HTTP action works with given params, the HTTP action will work too.<br/>
Otherwise, HTTP action will return "404 NotFound" error.

**Example:**

```ruby
class News < E

    def edit id
        return "ID = #{id}"
    end
end
```

**If** the browser make a request like /news/edit/100<br/>
it will receive the "ID = 100" response.

**However**, if it will make a request like /news/edit<br/>
it will receive an "404 NotFound" error, cause News#edit can not be called without arguments.

**But**, as HTTP actions works just like Ruby methods, we can give default values to params.

**Example:**

```ruby
class News < E

    def edit id = 0
        return "ID = #{id}"
    end
end
```

Now, if browser will make a request like /news/edit<br/>
it will receive the "ID = 0" response.

*Worth to note* that HTTP actions will work with any combination of params an usual Ruby method will work with.

**Example:** - Splat params

```ruby
class News < E

    def edit id, *columns
        return "ID = #{id}; Columns = #{columns}"
    end
end
```

If browser will make a request like /news/edit/100/name/content/status<br/>
it will receive the "ID = 100; Columns = ['name', 'content', 'status']" response.

## RESTful Actions

By default, defined actions will respond only to GET request method.

**Example:** - `index` action will respond only to GET request method

```ruby
class App < E

    def get_index
    end

    # or simply

    def index
    end
end
```

**Example:** - `news` action should respond to GET and POST request methods

```ruby
class App < E

    def news # or get_news
    end

    def post_news
    end
end
```

**Example:** - "GET /news" should return XML and "POST /news" should return JSON

```ruby
class App < E

    setup :news do
        content_type '.xml'
    end

    setup :post_news do
        content_type '.json'
    end

    def news
    end

    def post_news
    end
end
```

**Example:** - execute a callback only on POST requests

```ruby
class App < E

    setup /\Apost_/ do
        before { 'some logic' }
    end

    def news
    end

    def post_news
    end
end
```


## Aliases

As we already noted, any controller or slice may serve multiple root paths.

But what if we need an action to be available by multiple paths?

It's easy - add an standard Ruby alias.

**Example:**

```ruby
class App < E

    def news
        [__method__, action].inspect
    end
    alias :news____html :news
    alias :headlines__recent____html :news

end

Spec.new do
    app App

    r = get 'news'
    is?(r.body) == '[:news, :news]'
    #=> passed

    r = get 'news.html'
    is?(r.body) == '[:news, :news____html]'
    #=> passed

    r = get 'headlines/recent.html'
    is?(r.body) == '[:news, :headlines__recent____html]'
    #=> passed
end
```

## Rewriter

Espresso uses a really flexible rewrite engine,
which allow to redirect browser to new address
as well as pass control to arbitrarry controller(without redirect)
or just send response to browser(without redirect).

Rewrite rules can be added at app level.

A rewrite rule consist of regular expression and a block that receives matches as arguments.

`redirect` and `permanent_redirect` will redirect browser to new address with 302 and 301 codes respectivelly.

**Example:**

```ruby
app = SomeController.mount
app.rewrite /\A\/(.*)\.php$/ do |title|
    redirect SomeController.route(:index, title)
end
app.run
```

`pass` will pass control to an arbitrary controller, without redirect.

**Example:**

```ruby
app = SomeController.mount
app.rewrite /\A\/latest\/(.*)\.html/ do |type|
    pass SomeController, :latest_items, :type => type
end
app.run
```

`halt` will directly send response to browser, without redirect.

It accepts from 0 to 3 arguments.<br/>
If argument is a hash, it is added to headers.<br/>
If argument is a Integer, it is treated as Status-Code.<br/>
Any other arguments are treated as body.

If a single argument given and it is an Array, it is treated as a bare Rack response and instantly sent to browser.

**Example:**

```ruby
app = SomeController.mount
app.rewrite /\A\/archived\/(.*)\.html/ do |title|
    if page = Model::Page.first(:url => title)
        halt page.content, 'Last-Modified' => page.last_modified.to_rfc2822
    else
        halt 404, 'page not found'
    end
end
app.run
```
