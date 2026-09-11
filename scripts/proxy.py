import socket
import select
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request

class ProxyHandler(BaseHTTPRequestHandler):
    def do_CONNECT(self):
        address = self.path.split(":")
        port = int(address[1])
        host = address[0]
        try:
            s = socket.create_connection((host, port), timeout=10)
        except Exception as e:
            self.send_error(502, f"Bad Gateway: {e}")
            return

        self.send_response(200, "Connection Established")
        self.end_headers()

        conns = [self.connection, s]
        while True:
            r, w, x = select.select(conns, [], conns, 30)
            if x or not r:
                break
            for c in r:
                data = c.recv(32768)
                if not data:
                    return
                if c is self.connection:
                    s.sendall(data)
                else:
                    self.connection.sendall(data)

    def do_GET(self):
        req = urllib.request.Request(self.path, headers=dict(self.headers))
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                self.send_response(resp.status)
                for k, v in resp.getheaders():
                    self.send_header(k, v)
                self.end_headers()
                self.wfile.write(resp.read())
        except Exception as e:
            self.send_error(500, str(e))

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    server = HTTPServer(('0.0.0.0', port), ProxyHandler)
    print(f"Proxy serving on port {port}")
    server.serve_forever()
