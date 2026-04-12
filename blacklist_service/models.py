import uuid
from datetime import datetime, timezone

from blacklist_service import db


class BlacklistEntry(db.Model):
    __tablename__ = "blacklist_entries"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = db.Column(db.String(320), nullable=False, unique=True, index=True)
    app_uuid = db.Column(db.String(36), nullable=False)
    blocked_reason = db.Column(db.String(255), nullable=True)
    ip_address = db.Column(db.String(45), nullable=False)
    created_at = db.Column(
        db.DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
