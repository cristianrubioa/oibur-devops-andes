import os

from dotenv import load_dotenv

load_dotenv()


def get_settings():
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise RuntimeError("DATABASE_URL is required (use PostgreSQL for local and cloud environments).")

    return {
        "SQLALCHEMY_DATABASE_URI": database_url,
        "SQLALCHEMY_TRACK_MODIFICATIONS": False,
        "JWT_SECRET_KEY": os.getenv("JWT_SECRET_KEY", "dev-jwt-secret"),
        "AUTH_BEARER_TOKEN": os.getenv("AUTH_BEARER_TOKEN", "static-token"),
    }
