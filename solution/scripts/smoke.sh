#!/usr/bin/env bash
set -euo pipefail
NS=${1:-three-tier}
REL=${2:-three-tier}

echo "[smoke] checking pods"
kubectl -n "$NS" get pods -o wide

echo "[smoke] checking backend health"
kubectl -n "$NS" port-forward svc/${REL}-backend 5000:5000 >/tmp/pf-backend.log 2>&1 &
PF=$!
trap 'kill $PF >/dev/null 2>&1 || true' EXIT
sleep 2
curl -fsS http://localhost:5000/api/healthz

echo "
[smoke] ok"
