from flask import request
from flask_restful import Resource
from marshmallow import ValidationError

from blacklist_service import db
from blacklist_service.auth import require_static_bearer
from blacklist_service.models import BlacklistEntry
from blacklist_service.schemas import BlacklistCreateSchema

create_schema = BlacklistCreateSchema()


def _request_ip():
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    return request.remote_addr or "0.0.0.0"


class BlacklistCollectionResource(Resource):
    method_decorators = [require_static_bearer]

    def post(self):
        payload = request.get_json(silent=True) or {}
        try:
            data = create_schema.load(payload)
        except ValidationError as exc:
            return {"error": "Validation error", "details": exc.messages}, 400

        email = data["email"].strip().lower()
        app_uuid = str(data["app_uuid"])
        blocked_reason = data.get("blocked_reason")

        if BlacklistEntry.query.filter_by(email=email).first():
            return {"message": "Email is already in blacklist"}, 200

        entry = BlacklistEntry(
            email=email,
            app_uuid=app_uuid,
            blocked_reason=blocked_reason,
            ip_address=_request_ip(),
        )
        db.session.add(entry)
        db.session.commit()

        return {"message": "Email added to blacklist", "email": email}, 201


class BlacklistItemResource(Resource):
    method_decorators = [require_static_bearer]

    def get(self, email: str):
        normalized_email = email.strip().lower()
        entry = BlacklistEntry.query.filter_by(email=normalized_email).first()

        if not entry:
            return {
                "email": normalized_email,
                "is_blacklisted": False,
                "blocked_reason": None,
            }, 200

        return {
            "email": normalized_email,
            "is_blacklisted": True,
            "blocked_reason": entry.blocked_reason,
        }, 200
