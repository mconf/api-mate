var http = require('http'),
  httpProxy = require('http-proxy'),
  fs = require('fs'),
  colors = require('colors');

// Read or create the configuration file
var config;
var configFile = '.target.json';
if (fs.existsSync(configFile)) {
  console.log(('Found configuration file ' + configFile + ', using it').blue.bold);
  file = fs.readFileSync(configFile, { encoding: 'utf8' });
  config = JSON.parse(file);
} else {
  console.log(('Did not find configuration file ' + configFile + ', creating it').blue.bold);
  config = {
    "host": "test-install.blindsidenetworks.com",
    "port": 80
  };
  fs.writeFileSync(configFile, JSON.stringify(config, null, 2), { encoding: 'utf8' });
}

opts = {
  // without this option BigBlueButton/nginx will not redirect the call
  // properly to bigbluebutton-web
  changeOrigin: true
};
var proxy = new httpProxy.RoutingProxy(opts);
http.createServer(function (req, res) {
  console.log("Request received:".yellow, req.method, req.url);

  if (req.method === 'OPTIONS') {
    console.log('It\'s a OPTIONS request, sending a default response'.green);
    var headers = {};
    headers["Access-Control-Allow-Origin"] = "*";
    headers["Access-Control-Allow-Methods"] = "POST, GET, PUT, DELETE, OPTIONS";
    headers["Access-Control-Allow-Credentials"] = false;
    headers["Access-Control-Max-Age"] = '86400'; // 24 hours
    headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Accept";
    res.writeHead(200, headers);
    res.end();
  } else {

    // we don't proxy join requests, redirect the user directly to the join url
    if (req.url.match(/\/join\?/)) {
      // TODO: get the protocol used in the request
      var destination = 'http://' + config.host + ':' + config.port + req.url;
      console.log('It\'s a join, redirecting to:'.green, destination);
      res.writeHead(302, { Location: destination });
      res.end();

    } else {

      // accept cross-domain requests for all requests
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type');

      // proxy everything to the target server
      var buffer = httpProxy.buffer(req);
      proxy.proxyRequest(req, res, {
        port: config.port,
        host: config.host,
        buffer: buffer
      });
    }

  }

}).listen(8000);

proxy.on('end', function () {
  console.log("The request was proxied".green);
});

console.log(('Server started at localhost:8000, proxying to ' + config.host + ':' + config.port).blue.bold);
