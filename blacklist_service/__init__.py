from flask import Flask
from flask_jwt_extended import JWTManager
from flask_marshmallow import Marshmallow
from flask_restful import Api
from flask_sqlalchemy import SQLAlchemy
from blacklist_service.settings import get_settings

db = SQLAlchemy()
ma = Marshmallow()
jwt = JWTManager()


def create_app(test_config=None):
    app = Flask(__name__)
    _configure_app(app, test_config)

    db.init_app(app)
    ma.init_app(app)
    jwt.init_app(app)

    from blacklist_service.resources.blacklists import BlacklistCollectionResource, BlacklistItemResource
    from blacklist_service.resources.health import HealthResource

    api = Api(app)
    api.add_resource(BlacklistCollectionResource, "/blacklists")
    api.add_resource(BlacklistItemResource, "/blacklists/<string:email>")
    api.add_resource(HealthResource, "/health")

    with app.app_context():
        db.create_all()

    return app


def _configure_app(app: Flask, test_config=None):
    if test_config:
        app.config.update(test_config)
        if app.config.get("SQLALCHEMY_DATABASE_URI"):
            app.config.setdefault("SQLALCHEMY_TRACK_MODIFICATIONS", False)
            app.config.setdefault("JWT_SECRET_KEY", "test-jwt-secret")
            app.config.setdefault("AUTH_BEARER_TOKEN", "test-token")
            return

    app.config.update(get_settings())
