
## Intro


`crudify` method will automatically create CRUD actions that will map HTTP requests to corresponding methods on given Resource.

<pre>
<b>Request                        Resource</b>
GET     /id                    #get(id)
POST    /   with POST data     #create(post_params)
PUT     /id with POST data     #get(id).update(post_params)
PATCH   /id with POST data     #get(id).update(post_params)
DELETE  /id                    #get(id).delete OR #delete(id)
HEAD    /id                    #get(id)
OPTIONS /                      returns actions available to client
</pre>

**[ [contents &uarr;](https://github.com/slivu/espresso#tutorial) ]**


## Resource


First argument is required and should provide the CRUDified resource.<br/>
Resource should respond to `get` and `create` methods.<br/>
Objects that will be created/returned by resource should respond to `update` and `delete` methods.

Additionally, your resource may respond to `delete` method.<br/>
If it does, `delete` action will rely on it when deleting objects.<br/>
Otherwise, it will fetch the object by given ID and call `delete` on it.

If your resource/objects behaves differently, you can map its methods by passing them as options.<br/>
Let's suppose you are CRUDifying an DataMapper model.<br/>
To delete an DataMapper object you should call `destroy` on it,
so we simply mapping `delete` action to `destroy` method:

```ruby
crudify ModelName, :delete => :destroy
```

If your resource creating records by `new` instead of `create`,
simply map `post` action to `new` method:

```ruby
crudify ModelName, :post => :new
```

**[ [contents &uarr;](https://github.com/slivu/espresso#tutorial) ]**


## Root


By default, `crudify` will create actions that respond to controllers root.

```ruby
class App < E
    map '/'

    crudify SomeModel
end

# App controller will respond to
# GET /
# POST /
# PUT /
# etc.
```

To route CRUD actions to a different root, simply pass the root as second argument:

```ruby
class App < E
    map '/'

    crudify UsersModel, :users
end

# now App controller will respond to
# GET /users
# POST /users
# PUT /users
# etc.
```

**[ [contents &uarr;](https://github.com/slivu/espresso#tutorial) ]**


## Response


By default, objects are returned to client as they fetched from resource.<br/>
To prepare them accordingly before sending to client, use a block.<br/>
The block will receive the object as first argument.

```ruby
crudify UsersModel do |obj|
    case
        when post?, put?, patch?
            obj.id
        when head?
            last_modified obj.last_modified
        else
            content_type '.json'
            obj.to_json
    end
end
```

In the example above, we return object ID on POST, PUT, and PATCH requests.<br/>

On HEAD requests, the framework is always sending an empty body,
so we only update the headers.<br/>
This way the client may decide when to fetch the object.

On GET requests it will convert object to JSON before it is sent to client.<br/>
Also `content_type` is used to set proper content type.

DELETE action does not need a handler cause it ever returns an empty string.

**[ [contents &uarr;](https://github.com/slivu/espresso#tutorial) ]**


## Access Restriction


Using `auth` will instruct client to require authorization.<br/>
Access can be restricted to some or all actions.

In example below we will restrict access to Create, Update and Delete actions:

```ruby
class App < E
    # ...

    auth :post_index, :put_index, :patch_index, :delete_index do |user, pass|
        [user, pass] = ['admin', 'someReally?secretPass']
    end

    crudify ModelName
end
```

Now, when an client will want to POST, PUT, PATCH, DELETE,
it will be asked for authorization.

And an OPTIONS request will return all actions for authorized clients and
only GET, HEAD, OPTIONS for non-authorized clients.

If an root given, `crudify` will create actions that responds to that root,
thus actions name will contain given root.

In example below, `crudify` will create actions like `get_users`, `post_users`, `put_users` etc.<br/>
That's why we should specify proper action name in `auth` for authorization to work:

```ruby
class App < E
    # ...

    auth :post_users, :put_users, :patch_users, :delete_users do |user, pass|
        [user, pass] = ['admin', 'someReally?secretPass']
    end

    crudify UsersModel, :users
end
```

**[ [contents &uarr;](https://github.com/slivu/espresso#tutorial) ]**
