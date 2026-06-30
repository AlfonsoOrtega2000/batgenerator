import json, time, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _auth import check, token_for
from _base import BaseHandler


class handler(BaseHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        try:
            data = json.loads(self.rfile.read(length))
        except Exception:
            self._error(400, "JSON invalido")
            return

        user = data.get("username", "")
        pw   = data.get("password", "")

        if check(user, pw):
            self._json(200, {"token": token_for(user, pw)})
        else:
            time.sleep(3)
            self._error(401, "Usuario o contrasena incorrectos")
