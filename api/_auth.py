import hmac, hashlib

_SECRET = b"opt-batgen-2025"
_USERS  = {"admin": "RDP57g7P"}

def _tok(user, pw):
    return hmac.new(_SECRET, f"{user}:{pw}".encode(), hashlib.sha256).hexdigest()

VALID_TOKENS = {_tok(u, p) for u, p in _USERS.items()}

def check(user, pw):
    return user in _USERS and _USERS[user] == pw

def token_for(user, pw):
    return _tok(user, pw)
