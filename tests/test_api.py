from blacklist_service import create_app, db


def make_client():
    app = create_app(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
            "AUTH_BEARER_TOKEN": "test-token",
        }
    )

    with app.app_context():
        db.drop_all()
        db.create_all()

    return app.test_client()


def auth_headers():
    return {"Authorization": "Bearer test-token"}


def test_health_ok():
    client = make_client()
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "ok"


def test_blacklist_create_and_query():
    client = make_client()

    payload = {
        "email": "User@Test.com",
        "app_uuid": "123e4567-e89b-12d3-a456-426614174000",
        "blocked_reason": "Fraude",
    }

    create_response = client.post("/blacklists", json=payload, headers=auth_headers())
    assert create_response.status_code == 201

    query_response = client.get("/blacklists/user@test.com", headers=auth_headers())
    assert query_response.status_code == 200
    data = query_response.get_json()
    assert data["is_blacklisted"] is True
    assert data["blocked_reason"] == "Fraude"


def test_blacklist_query_not_found():
    client = make_client()
    response = client.get("/blacklists/nope@test.com", headers=auth_headers())
    assert response.status_code == 200
    data = response.get_json()
    assert data["is_blacklisted"] is False
    assert data["blocked_reason"] is None


def test_blacklist_rejects_invalid_token():
    client = make_client()
    response = client.get(
        "/blacklists/nope@test.com",
        headers={"Authorization": "Bearer wrong"},
    )
    assert response.status_code == 401


def test_blacklist_rejects_invalid_payload():
    client = make_client()
    response = client.post(
        "/blacklists",
        json={"email": "bad-email", "app_uuid": "not-uuid"},
        headers=auth_headers(),
    )
    assert response.status_code == 400
