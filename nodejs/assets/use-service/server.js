var http = require("http");

http.createServer(function(request, response) {
    response.writeHead(200, {'Content-Type': 'application/json'});
    var options = {
        host: "get-hostname",
        path: "/"
    };
    var callback = function(innerResponse) {
        var chunks = [];
        innerResponse.on('data', function(chunk) {
            console.log(chunk)
            chunks.push(chunk);
        });
        innerResponse.on('end', function() {
            var jsonData = chunks.join('');
            var data = JSON.parse(jsonData);
            response.write(`Got a response from ${data.HOSTNAME}!`);
            response.end();
        });
    };
    http.request(options, callback).end();
}).listen(3000);
