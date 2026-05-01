#!/usr/bin/env bash
set -euo pipefail
docker compose down -v --remove-orphans 2>/dev/null || true
docker image rm searchpulse-frontend searchpulse-backend 2>/dev/null || true
for p in 3000 8080 5432; do
  pid=$(lsof -ti tcp:$p 2>/dev/null || true)
  [ -n "$pid" ] && kill -9 $pid 2>/dev/null || true
done
echo "  ✅ cleaned — ports 3000 8080 5432 freed"
