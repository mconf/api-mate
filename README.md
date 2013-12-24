API Mate
========

API Mate is a web application (a simple web page) to access the APIs of [BigBlueButton](http://bigbluebutton.org) and [Mconf](http://mconf.org).

Usage
-----

* Use it online at http://mconf.github.com/api-mate; or
* Get the latest version from the branch [`gh-pages`](https://github.com/mconf/api-mate/tree/gh-pages) and
  open `index.html` in your browser.


## Allow cross-domain requests

The API Mate runs on your web browser and most of the API methods are accesssed through HTTP GET
calls, so you can simply click on a link in the API Mate and you'll access the API method.

However, for some other methods (such as API methods accessed via POST) or some more advanced
features, we need to run API calls from the javascript using ajax. This will result in a cross-domain
request, since a web page (the API Mate) is making requests directly to another server (your web
conference server). Since cross-domain requests are by default disabled in the browser, they will
all fail.

We offer two solutions:

1. Change your BigBlueButton/Mconf-Live server to accept cross-domain requests (ok, but only
   recommended for development and testing); or
2. Use a local proxy that will receive the calls and proxy them to your web conference server.

### 1. Change your server to accept cross-domain requests

With this option you will enable cross-origin requests using
[CORS](http://en.wikipedia.org/wiki/Cross-origin_resource_sharing) on your BigBlueButton/Mconf-Live server.

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

If you need a more detailed and controlled example, [try this one](http://enable-cors.org/server_nginx.html).

#### On [Node.js](http://nodejs.org/) with [Express.js](http://expressjs.com/):

If you're not accessing your web conference server directly, but through an application written in
Node.js, you can use the following code to enable cross-domain requests:

```coffeescript
app.all '*', (req, res, next) ->
  res.header("Access-Control-Allow-Origin", "*")
  res.header("Access-Control-Allow-Headers", "X-Requested-With, Content-Type")
  next()
```

[Source](http://enable-cors.org/server_expressjs.html).


### 2. Use a local proxy

There's an application that can be used as a local proxy called `api-mate-proxy` available in this
repository, in the folder [proxy](https://github.com/mconf/api-mate/tree/master/proxy).

It is a very simple Node.js application that you can run locally to receive all requests
from the API Mate and proxy them to your web conference server.

#### Usage

See `api-mate-proxy`'s [README file](https://github.com/mconf/api-mate/tree/master/proxy).


Development
-----------

At first, install [Node.js](http://nodejs.org/) (see `package.json` for the specific version required).

Install the dependencies with:

    npm install

Then compile the source files with:

    cake build

This will compile all files inside `src/` to formats that can be opened in the browser and place them into `/lib`.

To watch for changes and compile the files automatically, run:

    cake watch


License
-------

Distributed under The MIT License (MIT), see `LICENSE`.
