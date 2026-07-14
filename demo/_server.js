const http = require('http');
const fs = require('fs');
const path = require('path');

const root = __dirname;
const port = 8080;

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
};

const server = http.createServer(function (req, res) {
  let urlPath = decodeURIComponent(req.url.split('?')[0]);
  if (urlPath === '/') urlPath = '/overdue-book-night-a.html';
  const filePath = path.join(root, urlPath);
  if (filePath.indexOf(root) !== 0) {
    res.writeHead(403);
    res.end('forbidden');
    return;
  }
  fs.readFile(filePath, function (err, data) {
    if (err) {
      res.writeHead(404);
      res.end('not found');
      return;
    }
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': types[ext] || 'application/octet-stream' });
    res.end(data);
  });
});

server.listen(port, '0.0.0.0', function () {
  console.log('serving on http://localhost:' + port + '/');
});
