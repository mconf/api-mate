# API Mate - HTTP Proxy

## Usage

First, install [Node.js](nodejs.org). See the adequate version in [package.json](https://github.com/mconf/api-mate/blob/http-proxy/proxy/package.json).

Get the source, set up the proxy and run it for the first time:

```bash
git clone https://github.com/mconf/api-mate.git
cd api-mate/proxy
npm install
node index.js
```

You should see:

```bash
Found configuration file .target.json, using it
Server started at localhost:8000, proxying to test-install.blindsidenetworks.com:80
```

The first time you run it, it will create a configuration file (`.target.json`) for you pointing to the default test server from Blindside Networks at `test-install.blindsidenetworks.com:80`. If you want to proxy the calls to a different server, set its address on `.target.json`.

Your proxy server will listen at `localhost:8000`, so all you have to do is point the API Mate to this address (and use the salt of your web conference server!):

![Use localhost:8000 as the server in the API Mate](https://raw.github.com/mconf/api-mate/master/proxy/img/api-mate-server.png "Use localhost:8000 as the server in the API Mate")

As you make requests from the API Mate to your proxy, the proxy will print information of the requests it received.
You will notice that the only request that is not proxied is `join`. In this case the user is redirected directly to
the web conference server.

![Example of output given by the proxy](https://raw.github.com/mconf/api-mate/master/proxy/img/proxy-output.png "Example of output given by the proxy")
