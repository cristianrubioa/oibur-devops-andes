from functools import wraps

from flask import current_app, request


def require_static_bearer(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        expected = current_app.config["AUTH_BEARER_TOKEN"]

        if not auth_header.startswith("Bearer "):
            return {"error": "Missing or invalid Authorization header"}, 401

        token = auth_header.split(" ", 1)[1].strip()
        if token != expected:
            return {"error": "Invalid bearer token"}, 401

        return func(*args, **kwargs)

    return wrapper
