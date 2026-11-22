#!/usr/bin/env python3
"""
backend.py  —  a tiny REST backend for the CN project.
No extra installs needed (uses only Python's built-in library).

Run on Mac 3, in TWO separate Terminal windows:

    python3 backend.py A 3001        <- Backend A
    python3 backend.py B 3002        <- Backend B

Stop a backend with Ctrl + C.

Endpoints:
    GET /             -> small HTML page.  Cache-Control: max-age=60 + ETag  (caching demo)
    GET /api/status   -> {"backend": "A", "status": "ok"}   (never cached)
Every response has the header   X-Backend: A   (or B)
"""
import hashlib
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

# The home page is IDENTICAL on A and B on purpose: then both backends give the
# same ETag, so the "304 Not Modified" demo works no matter which backend answers.
HOME_PAGE = b"""<!doctype html>
<html>
<head><meta charset="utf-8"><title>Team service</title></head>
<body>
  <h1>Team service is running</h1>
  <p>Look at the <b>X-Backend</b> response header to see which backend answered.</p>
  <p>Try <a href="/api/status">/api/status</a></p>
</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):
    backend_name = "?"

    def do_GET(self):
        self.reply(send_body=True)

    def do_HEAD(self):            # used by "curl -I"
        self.reply(send_body=False)

    def reply(self, send_body):
        if self.path == "/api/status":
            body = json.dumps({"backend": self.backend_name, "status": "ok"}).encode()
            content_type = "application/json"
            cache = "no-store"                       # always ask the server
        elif self.path == "/":
            body = HOME_PAGE
            content_type = "text/html; charset=utf-8"
            cache = "public, max-age=60"             # may be reused for 60 seconds
        else:
            body = json.dumps({"error": "not found", "path": self.path}).encode()
            self.send(404, body, "application/json", "no-store", None, send_body)
            return

        # ETag = a short "fingerprint" of the content
        etag = '"' + hashlib.sha1(body).hexdigest()[:16] + '"'

        # Conditional request: the client says "I already have version <etag>".
        # If it is still the same, answer 304 Not Modified with NO body.
        if self.headers.get("If-None-Match") == etag:
            self.send(304, b"", None, cache, etag, False)
            return

        self.send(200, body, content_type, cache, etag, send_body)

    def send(self, code, body, content_type, cache, etag, send_body):
        self.send_response(code)
        self.send_header("X-Backend", self.backend_name)
        if content_type:
            self.send_header("Content-Type", content_type)
        if code != 304:
            self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", cache)
        if etag:
            self.send_header("ETag", etag)
        self.end_headers()
        if send_body:
            self.wfile.write(body)


def main():
    if len(sys.argv) != 3:
        print("Usage:   python3 backend.py <NAME> <PORT>")
        print("Example: python3 backend.py A 3001")
        sys.exit(1)

    name, port = sys.argv[1], int(sys.argv[2])
    Handler.backend_name = name

    try:
        # "0.0.0.0" = listen on ALL network interfaces, so other Macs can connect.
        # (127.0.0.1 would mean "only this Mac" and nginx on Mac 2 could not reach it.)
        server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    except OSError as e:
        print(f"ERROR: cannot use port {port}: {e}")
        print("Is this backend already running in another Terminal window?")
        sys.exit(1)

    print(f"Backend {name} is running on port {port} (listening on 0.0.0.0 = all interfaces)")
    print("Every request is printed below. The first IP on each line is WHO connected.")
    print("Press Ctrl + C to stop.\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print(f"\nBackend {name} stopped.")


if __name__ == "__main__":
    main()
