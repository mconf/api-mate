var express = require('express');
var fs = require('fs');
var subscribe = require('redis-subscribe-sse');
var bodyParser = require('body-parser');
var redis = require("redis");
var corser = require("corser");

// Main definitions
var path = '';

var app = express();
var redisClient = redis.createClient();

app.use(corser.create()); // for CORS
app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies

app.get(path + '/pull', function(req, res) {
    var sse;

    sse = subscribe({
        channels: '*',
        retry: 5000,
        host: '127.0.0.1',
        port: 6379,
        patternSubscribe: true
    });

    req.socket.setTimeout(0);

    res.set({
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*'
    });

    sse.pipe(res).on('close', function() {
        sse.close();
    });
});

app.post(path + '/push', function(req, res) {
    var data = req.body.data;
    var channel = req.body.channel;

    console.log("<== publishing", data, "in channel", channel);
    redisClient.publish(channel, JSON.stringify(data));

    res.set({
        'Content-Type': 'text/plain',
        'Cache-Control': 'no-cache',
        'Access-Control-Allow-Origin': '*'
    });
    res.writeHead(200);
    res.end();
});

var server = app.listen(3000, function() {
    console.log('Listening on port %d', server.address().port);
});
