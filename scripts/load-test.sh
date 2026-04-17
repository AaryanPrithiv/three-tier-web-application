#!/usr/bin/env bash
set -euo pipefail

for i in {1..5}; do
  curl -fsS -X POST http://localhost:8080/api/visit >/dev/null
done

curl -fsS http://localhost:8080/api/status
