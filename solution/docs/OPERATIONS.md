# Operations Guide – three-tier-webapp

This guide covers common operational actions: deploy, upgrade, rollback, scale, debug, and backup/restore.

## Deploy
```bash
helm upgrade --install three-tier ./charts/three-tier-webapp -n three-tier --create-namespace
```

## Upgrade
1) Change image tag (example):
```bash
helm upgrade three-tier ./charts/three-tier-webapp -n three-tier   --set backend.image.tag=<new-tag>
```
2) Watch rollout:
```bash
kubectl -n three-tier rollout status deploy/three-tier-backend
```

### Rollback (evidence)
```bash
helm -n three-tier history three-tier
helm -n three-tier rollback three-tier <REVISION>
kubectl -n three-tier rollout status deploy/three-tier-backend
```

## Scale
```bash
kubectl -n three-tier scale deploy/three-tier-frontend --replicas=3
kubectl -n three-tier scale deploy/three-tier-backend --replicas=3
```
If HPA enabled, use:
```bash
kubectl -n three-tier get hpa
```

## Debug Playbook

### 1) Verify objects
```bash
kubectl -n three-tier get pods,svc,ingress,pvc
kubectl -n three-tier describe pod <pod>
```

### 2) Logs
```bash
kubectl -n three-tier logs deploy/three-tier-backend --tail=200
kubectl -n three-tier logs sts/three-tier-postgres --tail=200
```

### 3) DB connectivity from backend pod
```bash
kubectl -n three-tier exec -it deploy/three-tier-backend -- sh -c 'nc -vz postgres 5432'
```

### 4) Readiness failures
```bash
kubectl -n three-tier describe pod <backend-pod> | sed -n '/Readiness probe/,/Events/p'
```

### 5) Storage/PVC issues
```bash
kubectl -n three-tier get pvc
kubectl -n three-tier describe pvc <pvc>
kubectl get sc
```

## RBAC Verification

### Workload SA has no API privileges
```bash
kubectl auth can-i list pods -n three-tier --as system:serviceaccount:three-tier:three-tier-backend
```
Expect: `no`.

### Ops SA can read objects
```bash
kubectl auth can-i list pods -n three-tier --as system:serviceaccount:three-tier:three-tier-ops
```
Expect: `yes`.

## Backup & Restore

### Verify backups
```bash
kubectl -n three-tier get cronjob
kubectl -n three-tier create job --from=cronjob/three-tier-pgdump manual-backup
kubectl -n three-tier logs job/manual-backup
kubectl -n three-tier exec -it job/manual-backup -- ls -lah /backups
```

### Restore (manual)
1) Pick a dump file on the backup PVC.
2) Run a restore job:
```bash
kubectl -n three-tier run pgrestore --rm -it   --image=postgres:16-alpine   --restart=Never   --env="PGPASSWORD=$(kubectl -n three-tier get secret three-tier-db -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)"   -- sh -c 'psql -h postgres -U appuser -d appdb < /backups/<dump.sql>'
```

Trade-off: In production, use object storage + encryption + tested restore procedures.
