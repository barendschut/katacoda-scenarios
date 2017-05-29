var http = require("http");

http.createServer(function(request, response) {
    response.writeHead(200, {'Content-Type': 'application/json'});
    response.write(JSON.stringify({
        HOSTNAME: process.env.HOSTNAME
    }, null, 2), "UTF-8")
}).listen(3000)
