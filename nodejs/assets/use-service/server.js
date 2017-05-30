var http = require("http");

http.createServer(function(request, response) {
    response.writeHead(200, {'Content-Type': 'application/json'});
    var options = {
        host: "get-hostname",
        path: "/"
    };
    callback = function(innerResponse) {
        var chunks = [];
        innerResponse.on('data', function(chunk) {
            chunks.push(chunk)
        });
        innerResponse.on('end', function() {
            var jsonData = chunks.join('')
            var data = JSON.parse(jsonData)
            response.write(`Got a response from ${data.HOSTNAME}!`)
        });
    }
    var req = http.request(options, callback);
    req.end()
}).listen(3000)
