#!/usr/bin/env bash
set -euo pipefail
NS=${1:-three-tier}
REL=${2:-three-tier}
OUT_DIR="$(cd "$(dirname "$0")" && pwd)/out"
mkdir -p "$OUT_DIR"

run() {
  local name="$1"; shift
  echo "
### $name" | tee "$OUT_DIR/${name}.md"
  echo "\`\`\`" | tee -a "$OUT_DIR/${name}.md"
  "$@" 2>&1 | sed -E 's/[0-9]{1,3}(\.[0-9]{1,3}){3}/<IP>/g' | tee -a "$OUT_DIR/${name}.md"
  echo "\`\`\`" | tee -a "$OUT_DIR/${name}.md"
}

run "01_objects" kubectl -n "$NS" get pods,svc,ingress,pvc
run "02_rollout_frontend" kubectl -n "$NS" rollout status deploy/${REL}-frontend
run "03_rollout_backend" kubectl -n "$NS" rollout status deploy/${REL}-backend
run "04_rollout_postgres" kubectl -n "$NS" rollout status sts/${REL}-postgres
run "05_rbac_backend_sa" kubectl auth can-i list pods -n "$NS" --as system:serviceaccount:${NS}:${REL}-backend
run "06_rbac_ops_sa" kubectl auth can-i list pods -n "$NS" --as system:serviceaccount:${NS}:${REL}-ops
run "07_helm_history" helm -n "$NS" history "$REL"

echo "
Evidence written to: $OUT_DIR"
