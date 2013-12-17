API Mate
========

API Mate is a web application (a simple web page) to access the APIs of [BigBlueButton](http://bigbluebutton.org) and [Mconf](http://mconf.org).

Usage
-----

Open `lib/api_mate.html` in your browser or check http://mconf.github.com/api-mate to use it.

Development
-----------

At first, install [Node.js](http://nodejs.org/) (see `package.json` for the specific version required).

Install the dependencies with:

    npm install

Then, to compile the source files with:

    cake build

This will compile all files inside `src/` to formats that can be opened in the browser that will be put into `/lib`.

To watch for changes and compile the files automatically run:

    cake watch

### Allow cross-domain requests for POST requests

To enable the API Mate to make POST requests to your server's API, the server has to enable cross-origin
requests using [CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing).

#### In BigBlueButton/Mconf-Live with Nginx

Copy to following block of code to the bottom of the file `/etc/bigbluebutton/nginx/web.nginx`, inside the
block `location /bigbluebutton`:

```
location /bigbluebutton {
    ...

    # add this block!
    if ($http_origin) {
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET,POST,OPTIONS";
        add_header Access-Control-Allow-Headers  Content-Type;
        add_header Access-Control-Max-Age        86400;
    }
}
```

Notice that it will allow cross-domain requests from **any** host, which is not recommended! Use it only
for test and development.

Save it and restart Nginx to apply the changes:

```bash
$ sudo /etc/init.d/nginx restart
```

If you need something better suited for production, [try this one](http://enable-cors.org/server_nginx.html).

#### On node.js with express.js:

```coffeescript
app.all '*', (req, res, next) ->
  res.header("Access-Control-Allow-Origin", "*")
  res.header("Access-Control-Allow-Headers", "X-Requested-With")
  next()
```

[Source](http://enable-cors.org/server_expressjs.html).


License
-------

Distributed under The MIT License (MIT), see `LICENSE`.
