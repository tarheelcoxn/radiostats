#!/bin/bash
#
# test-docker-deploy.sh - Test Docker deployment of radiostats
#
# Usage: ./test-docker-deploy.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "=== Radiostats Docker Deployment Test ==="
echo "Project directory: $PROJECT_DIR"
echo ""

# Check Docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Run provision.sh first."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "ERROR: Cannot connect to Docker. Are you in the docker group?"
    echo "Try: newgrp docker"
    exit 1
fi

cd "$PROJECT_DIR"

# Step 1: Check/create config files
echo "[1/5] Checking configuration files..."

if [[ ! -f config.yml ]]; then
    echo "  Creating config.yml from example..."
    cp deploy/dev-testbed/config.dev.yml.example config.yml

    # Update config for Docker networking (services use container names)
    # The example config should work for Docker deployment as-is
    echo "  NOTE: Using dev config. Edit config.yml for production settings."
fi

if [[ ! -f mounts.yml ]]; then
    echo "  Creating mounts.yml from example..."
    cp deploy/dev-testbed/mounts.dev.yml mounts.yml
fi

echo "  Config files ready."
echo ""

# Step 2: Build images
echo "[2/5] Building Docker images..."
docker compose build

echo ""

# Step 3: Start containers
echo "[3/5] Starting containers..."
docker compose up -d

echo ""

# Step 4: Wait for services to be ready
echo "[4/5] Waiting for services to start..."

MAX_WAIT=120
WAITED=0
INTERVAL=5

# Wait for backend to be ready
echo "  Waiting for backend..."
while ! curl -sf http://localhost:8000/admin/ -o /dev/null 2>/dev/null; do
    if [[ $WAITED -ge $MAX_WAIT ]]; then
        echo "  ERROR: Backend did not start within ${MAX_WAIT}s"
        echo ""
        echo "Backend logs:"
        docker compose logs --tail 30 backend
        exit 1
    fi
    sleep $INTERVAL
    WAITED=$((WAITED + INTERVAL))
    echo "    ... waited ${WAITED}s"
done
echo "  Backend is ready."

# Wait for frontend to be ready
echo "  Waiting for frontend..."
WAITED=0
while ! curl -sf http://localhost:3000/ -o /dev/null 2>/dev/null; do
    if [[ $WAITED -ge $MAX_WAIT ]]; then
        echo "  ERROR: Frontend did not start within ${MAX_WAIT}s"
        echo ""
        echo "Frontend logs:"
        docker compose logs --tail 30 frontend
        exit 1
    fi
    sleep $INTERVAL
    WAITED=$((WAITED + INTERVAL))
    echo "    ... waited ${WAITED}s"
done
echo "  Frontend is ready."

echo ""

# Step 5: Validate services
echo "[5/5] Validating services..."

PASS=0
FAIL=0

# Check container status
echo "  Container status:"
docker compose ps --format "table {{.Name}}\t{{.Status}}" | sed 's/^/    /'
echo ""

# Test frontend
echo -n "  Frontend (http://localhost:3000/): "
if curl -sf http://localhost:3000/ | grep -q "root" 2>/dev/null; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Test backend admin redirect
echo -n "  Backend admin (http://localhost:8000/admin/): "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/admin/)
if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "302" ]]; then
    echo "PASS (HTTP $HTTP_CODE)"
    PASS=$((PASS + 1))
else
    echo "FAIL (HTTP $HTTP_CODE)"
    FAIL=$((FAIL + 1))
fi

# Test backend API
echo -n "  Backend API (http://localhost:8000/backend/api/): "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/backend/api/)
if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" ]]; then
    echo "PASS (HTTP $HTTP_CODE)"
    PASS=$((PASS + 1))
else
    echo "FAIL (HTTP $HTTP_CODE)"
    FAIL=$((FAIL + 1))
fi

# Check database container
echo -n "  Database container: "
if docker compose ps db | grep -q "running" 2>/dev/null; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    echo "FAIL"
    FAIL=$((FAIL + 1))
fi

# Check agent container
echo -n "  Agent container: "
if docker compose ps agent | grep -q "running" 2>/dev/null; then
    echo "PASS"
    PASS=$((PASS + 1))
else
    # Agent may exit if icecast isn't configured - check if it ran at least
    AGENT_STATUS=$(docker compose ps agent --format "{{.Status}}" 2>/dev/null || echo "unknown")
    if [[ "$AGENT_STATUS" == *"Exited"* ]]; then
        echo "WARN (exited - may need icecast config)"
    else
        echo "FAIL"
        FAIL=$((FAIL + 1))
    fi
fi

echo ""
echo "=== Test Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [[ $FAIL -eq 0 ]]; then
    echo "SUCCESS: Docker deployment is working!"
    echo ""
    echo "Access the application:"
    echo "  - Frontend: http://localhost:3000"
    echo "  - Backend Admin: http://localhost:8000/admin/"
    echo ""
    echo "From your Mac host (with port forwarding configured):"
    echo "  - Frontend: http://localhost:3080"
    echo "  - Backend Admin: http://localhost:8080/admin/"
    echo ""
    echo "To stop: docker compose down"
    exit 0
else
    echo "FAILURE: Some tests failed. Check the logs above."
    echo ""
    echo "View logs with:"
    echo "  docker compose logs backend"
    echo "  docker compose logs frontend"
    echo "  docker compose logs agent"
    exit 1
fi
