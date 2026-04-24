# Kubernetes Administration Assessment – Solution (Helm-only)
This `/solution` directory contains a production-minded Helm deployment for the upstream **three-tier-web-application** repository.
Upstream app context (from the repo README):
- Frontend: Nginx serving HTML + proxying API calls
- Backend: Python Flask API
- Database: PostgreSQL
- The repo includes raw manifests under `k8s/` and example access to the backend health endpoint `/api/healthz`.
---
## Quick Start (fresh cluster)
> Works on kind/minikube/k3d and most managed clusters.
### 0) Prereqs
- kubectl
- Helm v3
- A Kubernetes cluster
### 1) Install
```bash
# from the repo root
cd solution 
export NAMESPACE=three-tier
export RELEASE=three-tier
helm upgrade --install "$RELEASE" ./charts/three-tier-webapp \
  -n "$NAMESPACE" \
  --create-namespace \
  -f ./charts/three-tier-webapp/values-prod.yaml \
  -f ./values-prod-kind.yaml


# Note
Build the docker file locally and pushed it in my registry

Because default container image configured in the chart is not accessible from the registry, or not available, resulting in imagePullBackOff

# Trouble shoot commands
docker build -t aaryan8/three-tier-backend:v1 ./backend
docker push aaryan8/three-tier-backend:v1

docker build -t aaryan8/three-tier-frontend:v1 ./frontend
docker push aaryan8/three-tier-frontend:v1


helm -n "$NAMESPACE" uninstall "$RELEASE"
kubectl delete ns "$NAMESPACE" --wait=false


kind load docker-image aaryan8/three-tier-frontend:v1 --name three-tier
kubectl rollout restart deployment three-tier-frontend -n three-tier


kubectl logs -f -l app.kubernetes.io/component=frontend -n three-tier
kubectl rollout restart deployment three-tier-backend -n three-tier

kubectl logs -f -l app.kubernetes.io/component=frontend -n three-tier
kubectl logs -f -l app.kubernetes.io/component=backend -n three-tier

# wait for workloads
kubectl -n "$NAMESPACE" rollout status deploy/${RELEASE}-frontend
kubectl -n "$NAMESPACE" rollout status deploy/${RELEASE}-backend
kubectl -n "$NAMESPACE" rollout status sts/${RELEASE}-postgres
```
### 2) Access the app
Option A (ingress):
```bash
kubectl -n "$NAMESPACE" get ingress
```
If you use an ingress controller, map the hostname (default `three-tier.local`) to the ingress IP.

Here I have used here  Ingress-nginx contoller was validated locally using kind cluster

Option B (port-forward):
```bash
kubectl -n "$NAMESPACE" port-forward svc/${RELEASE}-frontend 8080:80
# in another terminal
kubectl -n "$NAMESPACE" port-forward svc/${RELEASE}-backend 5000:5000
curl -sS http://localhost:5000/api/healthz
# open http://localhost:8080
```
### 3) Prove end-to-end
```bash
# send requests to increment the counter (if frontend triggers backend calls)
# or hit backend directly if repo exposes visit endpoint(s)
./scripts/smoke.sh "$NAMESPACE" "$RELEASE"
```
---
## Deliverables Map
- Helm chart: `solution/charts/three-tier-webapp`
- Ops guide: `solution/docs/OPERATIONS.md`
- Evidence helper scripts: `solution/evidence/*` (they generate command outputs you can paste into your submission)
---
## Design Notes (trade-offs & why)
### 1) Helm-only, single chart
A single chart keeps installation simple while still allowing per-component toggles (`frontend.enabled`, `backend.enabled`, `postgres.enabled`).
### 2) DB persistence: **StatefulSet + PVC**
The upstream repo runs Postgres as a `Deployment` with env vars (including plaintext password) . For production-minded practice, this solution uses a **StatefulSet** with `volumeClaimTemplates` so data survives pod rescheduling and restarts.
Trade-off: full HA Postgres requires replication/operator; out-of-scope for a simple app. We keep it single-replica but durable.
### 3) Secrets kept out of Git
Upstream manifests embed `POSTGRES_PASSWORD` in the backend deployment . This chart:
- Creates a Secret at install time
- Uses a stable password generation technique (`lookup` + `randAlphaNum`) to avoid password rotation on upgrades
Trade-off: In real production, you’d likely use External Secrets (ESO) + cloud secret manager.
### 4) Probes + rollouts
Backend health endpoint `/api/healthz` exists in upstream docs , so readiness/liveness/startup probes use it.
Rollouts use `maxUnavailable: 0` and `maxSurge: 1` to avoid downtime even for small replica counts.
### 5) Ingress
Upstream includes an Ingress with host `three-tier.local` . This chart keeps that default but allows controller-specific annotations and TLS in `values.yaml`.
### 6) RBAC least privilege
Workload ServiceAccounts have `automountServiceAccountToken: false` by default.
An optional `ops` ServiceAccount is created with **read-only namespace permissions** for troubleshooting.
### 7) Backup/restore (simple, evidence-friendly)
A CronJob runs `pg_dump` on a schedule and stores dumps on a dedicated PVC.
Trade-off: For production you’d push to object storage and test restores regularly.
---
## Reproduce evidence (screenshots / outputs)
Run:
```bash
./evidence/collect.sh "$NAMESPACE" "$RELEASE"
```
It will print commands + capture outputs to `solution/evidence/out/`.
> Reminder: mask cluster-sensitive info (node names, IPs, cloud account IDs) before sharing.
---
## Troubleshooting scenarios (what we test)
See `docs/OPERATIONS.md` for a structured debug playbook.
Common scenarios:
- Backend CrashLoop due to DB auth mismatch
- Postgres Pending due to StorageClass/PVC issues
- Ingress returns 404/503 due to className/annotations mismatch
- Rollout stuck due to failing readiness probe
---
## Bonus: environment overlays
- `values-dev.yaml`
- `values-prod.yaml`
---
## Clean up
```bash
helm -n "$NAMESPACE" uninstall "$RELEASE"
kubectl delete ns "$NAMESPACE" --wait=false
```
