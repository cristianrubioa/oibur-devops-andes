from marshmallow import Schema, fields


class BlacklistCreateSchema(Schema):
    email = fields.Email(required=True)
    app_uuid = fields.UUID(required=True)
    blocked_reason = fields.String(required=False, allow_none=True, validate=lambda s: len(s) <= 255)


class BlacklistResponseSchema(Schema):
    email = fields.Email(required=True)
    is_blacklisted = fields.Boolean(required=True)
    blocked_reason = fields.String(allow_none=True)
