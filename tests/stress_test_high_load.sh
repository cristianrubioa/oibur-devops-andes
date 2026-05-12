#!/usr/bin/env bash
set -euo pipefail

ALB="http://blacklist-microservice-alb-477685829.us-east-1.elb.amazonaws.com"
TOKEN="static-token"
PARALLEL=20
BATCHES=10

echo "=== Stress Test: High-Load Burst (Apdex Degradation) ==="
echo "Target: $ALB"
echo "Parallel per batch: $PARALLEL | Batches: $BATCHES"
echo "Starting at $(date)"
echo ""

post_blacklist() {
  local idx=$1
  local ts
  ts=$(date +%s%N)
  local email="highload.${idx}.${ts}@example.com"
  curl -s -o /dev/null -w "%{http_code} %{time_total}s" \
    -X POST "$ALB/blacklists" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$email\", \"app_uuid\": \"highload-app-$idx\", \"blocked_reason\": \"high load test $idx\"}"
}

get_blacklist() {
  local idx=$1
  local ts
  ts=$(date +%s%N)
  local email="highload.${idx}.${ts}@example.com"
  curl -s -o /dev/null -w "%{http_code} %{time_total}s" \
    -X GET "$ALB/blacklists/$email" \
    -H "Authorization: Bearer $TOKEN"
}

TOTAL=0

for batch in $(seq 1 $BATCHES); do
  echo "--- Burst batch $batch/$BATCHES (${PARALLEL} parallel requests) ---"
  PIDS=()

  for i in $(seq 1 $PARALLEL); do
    idx=$((($batch - 1) * $PARALLEL + $i))
    if [ $(($i % 2)) -eq 0 ]; then
      (code=$(get_blacklist $idx); echo "  [GET /blacklists] $code") &
    else
      (code=$(post_blacklist $idx); echo "  [POST /blacklists] $code") &
    fi
    PIDS+=($!)
    TOTAL=$((TOTAL + 1))
  done

  wait "${PIDS[@]}"
  echo "  batch $batch done"
  echo ""
done

echo "=== Done ==="
echo "Total requests sent: $TOTAL"
echo "Finished at $(date)"
echo ""
echo "Check New Relic APM > blacklist-microservice > Apdex to confirm degradation."
