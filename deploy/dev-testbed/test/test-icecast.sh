#!/bin/bash
#
# Test script for icecast testbed
#
# Verifies that icecast is running and all test mounts are active.
# Platform-agnostic - works with Docker, Lima, or native installs.
#
# Usage: ./test-icecast.sh [host] [port]
#   host: Icecast hostname (default: localhost)
#   port: Icecast port (default: 8001)
#
# Exit codes:
#   0 - All tests passed
#   1 - Icecast not responding
#   2 - Missing mounts
#   3 - Stream fetch failed

set -euo pipefail

HOST="${1:-localhost}"
PORT="${2:-8001}"
BASE_URL="http://${HOST}:${PORT}"

# Expected mounts
EXPECTED_MOUNTS=(
    "test-128.mp3"
    "test-64.mp3"
    "test.ogg"
    "test-128.aac"
    "test-48.aac"
    "test.opus"
)

echo "=== Icecast Testbed Verification ==="
echo ""
echo "Target: ${BASE_URL}"
echo ""

# Test 1: Check icecast responds
echo "[1/3] Checking icecast status..."
if ! STATUS=$(curl -sf "${BASE_URL}/status-json.xsl" 2>/dev/null); then
    echo "FAIL: Icecast not responding at ${BASE_URL}"
    echo "      Make sure icecast is running and port ${PORT} is accessible."
    exit 1
fi
echo "  OK: Icecast responding"

# Test 2: Verify all mounts are present
echo ""
echo "[2/3] Checking for expected mounts..."
MISSING=()
for mount in "${EXPECTED_MOUNTS[@]}"; do
    if echo "$STATUS" | grep -q "\"listenurl\":\"http://[^\"]*/${mount}\""; then
        echo "  OK: /${mount}"
    else
        echo "  MISSING: /${mount}"
        MISSING+=("$mount")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "FAIL: ${#MISSING[@]} mount(s) missing"
    exit 2
fi

# Test 3: Verify streams are producing data
echo ""
echo "[3/3] Verifying streams produce data..."
FAILED=()
for mount in "${EXPECTED_MOUNTS[@]}"; do
    # curl exits with code 28 on timeout, which is expected for streams
    # Temporarily disable pipefail to handle this
    set +o pipefail
    BYTES=$(curl -s --max-time 2 "${BASE_URL}/${mount}" 2>/dev/null | wc -c)
    set -o pipefail
    BYTES="${BYTES// /}"  # trim whitespace
    if [ -n "$BYTES" ] && [ "$BYTES" -gt 1000 ] 2>/dev/null; then
        echo "  OK: /${mount} (${BYTES} bytes in 2s)"
    else
        echo "  FAIL: /${mount} (only ${BYTES:-0} bytes)"
        FAILED+=("$mount")
    fi
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo "FAIL: ${#FAILED[@]} stream(s) not producing data"
    exit 3
fi

echo ""
echo "=== All tests passed ==="
echo ""
echo "Icecast testbed is running correctly at ${BASE_URL}"
exit 0
