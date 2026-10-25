#!/usr/bin/env python3
"""
Tiny deliberately-vulnerable demo web app for the DevSecOps course.

Two modes, selected by the APP_MODE environment variable:
  APP_MODE=vuln     -> /login builds its SQL by string concatenation (SQL-injectable)
  APP_MODE=patched  -> /login uses a parameterized query (injection fails)

Endpoints:
  GET /              -> simple HTML home page (returns 200; used for health/ZAP)
  GET /login?user=&pass=  -> "logs in"; returns a token on success

This is a TEACHING TARGET ONLY. Never run anything like this in production.
"""
import os
import sqlite3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

APP_MODE = os.environ.get("APP_MODE", "vuln")


def make_db():
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    conn.execute("CREATE TABLE users (user TEXT, pass TEXT, token TEXT)")
    conn.execute("INSERT INTO users VALUES ('admin', 's3cr3t', 'ADMIN-TOKEN-7f3a')")
    conn.execute("INSERT INTO users VALUES ('alice', 'password1', 'USER-TOKEN-91bc')")
    conn.commit()
    return conn


DB = make_db()


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="text/html"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.end_headers()
        self.wfile.write(body.encode())

    def log_message(self, *args):
        pass  # quiet

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/":
            self._send(200, "<html><body><h1>Demo App</h1>"
                            "<form action='/login'><input name='user'>"
                            "<input name='pass' type='password'>"
                            "<button>Login</button></form></body></html>")
            return
        if parsed.path == "/login":
            q = parse_qs(parsed.query)
            user = q.get("user", [""])[0]
            pw = q.get("pass", [""])[0]
            try:
                if APP_MODE == "patched":
                    # SECURE: parameters are bound, never concatenated.
                    cur = DB.execute(
                        "SELECT token FROM users WHERE user = ? AND pass = ?",
                        (user, pw),
                    )
                else:
                    # VULNERABLE: input concatenated straight into the SQL string.
                    query = ("SELECT token FROM users WHERE user = '"
                             + user + "' AND pass = '" + pw + "'")
                    cur = DB.execute(query)
                row = cur.fetchone()
            except Exception as e:
                self._send(200, "login error: %s" % e)
                return
            if row:
                self._send(200, "welcome — login success, token=%s" % row[0])
            else:
                self._send(200, "login failed")
            return
        self._send(404, "not found")


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "80"))
    print("demo app starting on :%d (APP_MODE=%s)" % (port, APP_MODE))
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()
