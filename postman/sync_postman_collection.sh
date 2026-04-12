#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${POSTMAN_API_KEY:-}" ]]; then
  echo "ERROR: POSTMAN_API_KEY is required" >&2
  exit 1
fi

if [[ -z "${POSTMAN_WORKSPACE_ID:-}" ]]; then
  echo "ERROR: POSTMAN_WORKSPACE_ID is required" >&2
  exit 1
fi

COLLECTION_FILE="postman/blacklist-microservice.collection.json"

if [[ ! -f "$COLLECTION_FILE" ]]; then
  echo "ERROR: Collection file not found: $COLLECTION_FILE" >&2
  exit 1
fi

COLLECTION_NAME=$(python - << 'PY'
import json
from pathlib import Path
p = Path('postman/blacklist-microservice.collection.json')
print(json.loads(p.read_text(encoding='utf-8'))['info']['name'])
PY
)

is_json() {
  python -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1
}

build_wrapped_payload() {
  python - << 'PY'
import json
from pathlib import Path
p = Path('postman/blacklist-microservice.collection.json')
collection = json.loads(p.read_text(encoding='utf-8'))
print(json.dumps({'collection': collection}))
PY
}

extract_uid_from_workspace() {
  local payload="$1"
  local collection_name="$2"
  printf '%s' "$payload" | python - "$collection_name" << 'PY'
import json
import sys

name = sys.argv[1]
try:
    resp = json.load(sys.stdin)
except Exception:
    print("")
    raise SystemExit(0)

for c in resp.get("workspace", {}).get("collections", []):
    if c.get("name") == name:
        print(c.get("uid", ""))
        break
PY
}

extract_uid_from_create() {
  local payload="$1"
  printf '%s' "$payload" | python - << 'PY'
import json
import sys

try:
    resp = json.load(sys.stdin)
except Exception:
    print("")
    raise SystemExit(0)

print(resp.get("collection", {}).get("uid", ""))
PY
}

WRAPPED_PAYLOAD=$(build_wrapped_payload)
COLLECTION_UID="${POSTMAN_COLLECTION_UID:-}"

# 1) explicit UID wins
if [[ -n "$COLLECTION_UID" ]]; then
  echo "Using explicit collection UID: $COLLECTION_UID"
fi

# 2) resolve by workspace collections to avoid cross-workspace duplicates
if [[ -z "$COLLECTION_UID" ]]; then
  echo "Resolving collection in workspace: $POSTMAN_WORKSPACE_ID"
  WORKSPACE_RESP=$(curl -sS -H "X-Api-Key: $POSTMAN_API_KEY" "https://api.getpostman.com/workspaces/$POSTMAN_WORKSPACE_ID")

  if ! printf '%s' "$WORKSPACE_RESP" | is_json; then
    echo "ERROR: Postman workspace response is not JSON." >&2
    printf '%s\n' "$WORKSPACE_RESP" | head -c 400 >&2
    exit 1
  fi

  COLLECTION_UID=$(extract_uid_from_workspace "$WORKSPACE_RESP" "$COLLECTION_NAME")
fi

if [[ -n "$COLLECTION_UID" ]]; then
  echo "Updating collection: $COLLECTION_UID"
  UPDATE_RESP=$(curl -sS -X PUT \
    -H "X-Api-Key: $POSTMAN_API_KEY" \
    -H "Content-Type: application/json" \
    --data-raw "$WRAPPED_PAYLOAD" \
    "https://api.getpostman.com/collections/$COLLECTION_UID")

  if ! printf '%s' "$UPDATE_RESP" | is_json; then
    echo "ERROR: Postman update response is not JSON." >&2
    printf '%s\n' "$UPDATE_RESP" | head -c 400 >&2
    exit 1
  fi
else
  echo "Creating collection in workspace: $POSTMAN_WORKSPACE_ID"
  CREATE_RESP=$(curl -sS -X POST \
    -H "X-Api-Key: $POSTMAN_API_KEY" \
    -H "Content-Type: application/json" \
    --data-raw "$WRAPPED_PAYLOAD" \
    "https://api.getpostman.com/collections?workspace=$POSTMAN_WORKSPACE_ID")

  if ! printf '%s' "$CREATE_RESP" | is_json; then
    echo "ERROR: Postman create response is not JSON." >&2
    printf '%s\n' "$CREATE_RESP" | head -c 400 >&2
    exit 1
  fi

  COLLECTION_UID=$(extract_uid_from_create "$CREATE_RESP")
fi

if [[ -z "$COLLECTION_UID" ]]; then
  echo "ERROR: Could not determine collection UID." >&2
  exit 1
fi

echo "Collection synced. UID: $COLLECTION_UID"
echo "Tip: if duplicates already exist, keep one UID and run with POSTMAN_COLLECTION_UID=<uid>"
