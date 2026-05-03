#!/usr/bin/env bash
set -euo pipefail
echo ""
echo "  ◈ SearchPulse — building & starting..."
echo ""
docker compose up --build -d
echo ""
echo "  Waiting for backend to be healthy..."
for i in $(seq 1 40); do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' searchpulse-api 2>/dev/null || echo "starting")
  if [ "$STATUS" = "healthy" ]; then
    echo "  ✅ Backend healthy!"
    break
  elif [ "$STATUS" = "unhealthy" ]; then
    echo "  ❌ Backend unhealthy. Logs:"
    docker compose logs backend
    exit 1
  fi
  printf "  %s\r" "waiting... ($i)"
  sleep 2
done
echo ""
echo "  ✅  http://localhost:3000"
echo "  🔌  http://localhost:8080/api/health"
echo ""
