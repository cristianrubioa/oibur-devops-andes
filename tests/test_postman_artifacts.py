import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COLLECTION_PATH = ROOT / "postman" / "blacklist-microservice.collection.json"
ENV_PATH = ROOT / "postman" / "local.postman_environment.json"


def _load_json(path: Path):
    with path.open("r", encoding="utf-8") as file:
        return json.load(file)


def test_collection_has_required_requests():
    collection = _load_json(COLLECTION_PATH)
    items = collection["item"]
    by_name = {item["name"]: item for item in items}

    assert "Health - GET /health" in by_name
    assert "Create blacklist entry - POST /blacklists" in by_name
    assert "Check blacklist entry - GET /blacklists/{email}" in by_name

    assert by_name["Health - GET /health"]["request"]["method"] == "GET"
    assert by_name["Create blacklist entry - POST /blacklists"]["request"]["method"] == "POST"
    assert by_name["Check blacklist entry - GET /blacklists/{email}"]["request"]["method"] == "GET"


def test_collection_uses_expected_auth_headers():
    collection = _load_json(COLLECTION_PATH)
    items = {item["name"]: item for item in collection["item"]}

    create_headers = items["Create blacklist entry - POST /blacklists"]["request"]["header"]
    query_headers = items["Check blacklist entry - GET /blacklists/{email}"]["request"]["header"]

    create_auth = next(h["value"] for h in create_headers if h["key"] == "Authorization")
    query_auth = next(h["value"] for h in query_headers if h["key"] == "Authorization")

    assert create_auth == "Bearer {{token}}"
    assert query_auth == "Bearer {{token}}"


def test_collection_declares_required_variables():
    collection = _load_json(COLLECTION_PATH)
    variables = {entry["key"] for entry in collection["variable"]}

    assert {"base_url", "token", "email", "app_uuid", "blocked_reason"}.issubset(variables)


def test_environment_has_required_values():
    environment = _load_json(ENV_PATH)
    values = {entry["key"]: entry["value"] for entry in environment["values"]}

    assert environment["_postman_variable_scope"] == "environment"
    assert values["base_url"].startswith("http")
    assert values["token"]
    assert values["email"]
    assert values["app_uuid"]
    assert values["blocked_reason"] is not None
