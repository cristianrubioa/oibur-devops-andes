#!/usr/bin/env bash
set -euo pipefail

ALB="http://blacklist-microservice-alb-477685829.us-east-1.elb.amazonaws.com"
TOKEN="static-token"
BATCH_SIZE=10
TOTAL_BATCHES=5

echo "=== Stress Test: Normal Mixed Load ==="
echo "Target: $ALB"
echo "Starting at $(date)"
echo ""

post_blacklist() {
  local idx=$1
  local email="stress.test.${idx}.$(date +%s%N)@example.com"
  curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$ALB/blacklists" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$email\", \"app_uuid\": \"test-app-$(shuf -i 1-999 -n1)\", \"blocked_reason\": \"stress test $idx\"}"
}

get_blacklist() {
  local email="stress.test.${1}.$(date +%s%N)@example.com"
  curl -s -o /dev/null -w "%{http_code}" \
    -X GET "$ALB/blacklists/$email" \
    -H "Authorization: Bearer $TOKEN"
}

get_health() {
  curl -s -o /dev/null -w "%{http_code}" \
    -X GET "$ALB/health"
}

error_invalid_token() {
  curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$ALB/blacklists" \
    -H "Authorization: Bearer INVALID_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"error.$(date +%s%N)@test.com\", \"app_uuid\": \"bad\", \"blocked_reason\": \"err\"}"
}

error_bad_payload() {
  curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$ALB/blacklists" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"not_email": "missing required fields"}'
}

TOTAL=0
PIDS=()

for batch in $(seq 1 $TOTAL_BATCHES); do
  echo "--- Batch $batch/$TOTAL_BATCHES ---"
  PIDS=()

  for i in $(seq 1 $BATCH_SIZE); do
    idx=$((($batch - 1) * $BATCH_SIZE + $i))
    mod=$((idx % 5))

    if [ $mod -eq 0 ]; then
      # ~20% error: alternate between invalid token and bad payload
      if [ $(($idx % 10)) -eq 0 ]; then
        (code=$(error_invalid_token); echo "  [ERR-TOKEN] $code") &
      else
        (code=$(error_bad_payload); echo "  [ERR-PAYLOAD] $code") &
      fi
    elif [ $mod -eq 1 ] || [ $mod -eq 2 ]; then
      (code=$(post_blacklist $idx); echo "  [POST /blacklists] $code") &
    elif [ $mod -eq 3 ]; then
      (code=$(get_blacklist $idx); echo "  [GET /blacklists/<email>] $code") &
    else
      (code=$(get_health); echo "  [GET /health] $code") &
    fi

    PIDS+=($!)
    TOTAL=$((TOTAL + 1))
  done

  wait "${PIDS[@]}"
  echo ""
done

echo ""
echo "=== Done ==="
echo "Total requests sent: $TOTAL"
echo "Finished at $(date)"
