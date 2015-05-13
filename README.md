API Mate
========

API Mate is a web application (a simple web page) to access the APIs of [BigBlueButton](http://bigbluebutton.org) and [Mconf](http://mconf.org).

Usage
-----

* Use it online at http://mconf.github.com/api-mate; or
* Get the latest version from the branch [`gh-pages`](https://github.com/mconf/api-mate/tree/gh-pages) and
  open `index.html` in your browser.


## Passing parameters in the URL

The API Mate HTML page accepts parameters in the URL to pre-configure all the inputs available in the
menu, that will define the links generated. You can, for instance, generate a link in your application
to redirect to the API Mate and automatically fill the server and the shared secret fields in the
API Mate so that it points to the server you want to use.

The URL below shows a few of the parameters that can be passed in the URL:

```
api_mate.html#server=http://my-server.com/bigbluebutton/api&sharedSecret=lsk8df74e400365b55e0987&meetingID=meeting-1234567&custom-calls=getMyData
```

The parameters should be passed in the hash part of the URL, so they are not submitted to the server.
This means the application at http://mconf.github.com/api-mate will not receive your server's URL
and shared secret. You can also pass these parameters in the search string part of the URL, but that means the server will have access to your parameters (might be useful if
you're hosting your own API Mate).

The server address and shared secret are defined in the URL parameters `server` and `sharedSecret`
(you can also use `salt`), respectively.

All the other parameters are matched by an HTML `data-api-mate-param` attribute that is defined
in all inputs in the API Mate. The input to define the meeting ID, for example, has this attribute
set as `data-api-mate-param='meetingID,recordindID'`, so you can use both `meetingID=something` or
`recordingID=something` in the URL and it will automatically fill the meeting ID input. The input
to define custom API calls has the attribute set as `data-api-mate-param='custom-calls'`, and this
is why in the URL above we used `custom-calls=getMyData`.


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

    [./node_modules/.bin/]cake build

This will compile all files inside `src/` to formats that can be opened in the browser and place them into `/lib`.

To watch for changes and compile the files automatically, run:

    [./node_modules/.bin/]cake watch


License
-------

Distributed under The MIT License (MIT), see `LICENSE`.
