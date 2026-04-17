# Three-Tier Web Application

This repo shows a simple three-tier app with a frontend, an API layer, and a PostgreSQL data layer.

## What you will practice

- Building a small frontend that talks to an API
- Writing a backend that reads and updates data
- Connecting the app to PostgreSQL
- Running the stack with Docker Compose and Kubernetes manifests
- Explaining the three-tier pattern in an interview

## Tech stack

- HTML
- Nginx
- Python
- Flask
- PostgreSQL
- Docker
- Kubernetes

## Folder guide

- `frontend/index.html` is the browser-facing UI
- `frontend/Dockerfile` builds the frontend container
- `frontend/nginx.conf` proxies API requests to the backend
- `backend/app.py` is the Flask API
- `backend/requirements.txt` lists Python dependencies
- `backend/Dockerfile` builds the API container
- `db/init.sql` creates the database table
- `docker-compose.yml` runs the full stack locally
- `k8s/` contains Kubernetes manifests for each tier
- `scripts/load-test.sh` sends a few sample requests

## Local run

```bash
cd backend
python -m venv .venv
.venv\\Scripts\\activate
pip install -r requirements.txt
python app.py
```

Open:

```text
http://localhost:5000/api/healthz
```

## Docker Compose

```bash
docker compose up --build
```

Open:

```text
http://localhost:8080
```

## Kubernetes flow

1. Create the namespace.
2. Deploy PostgreSQL.
3. Deploy the backend API.
4. Deploy the frontend.
5. Expose the frontend with a service or ingress.
6. Use the load test and confirm the visit count changes.

## Useful commands

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```

## Interview talking points

- The frontend handles user interaction.
- The backend handles business logic.
- PostgreSQL keeps the data durable.
- A three-tier split makes each layer easier to change and explain.

## Practice tasks

- Add a second API endpoint for a new metric.
- Persist a small list of notes instead of just a visit counter.
- Add a readiness probe to each deployment.
- Add an ingress object and route the frontend through it.
