#!/bin/bash
#
# Fake listener generator for icecast testbed
#
# WARNING: FOR DEVELOPMENT AND TESTING ONLY
#
# Creates simulated listeners that connect to icecast streams.
# Each listener downloads stream data to /dev/null for a random duration,
# then disconnects. This simulates realistic listener churn for testing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="${SCRIPT_DIR}/.fake-listeners.pids"

# Default values
DEFAULT_HOST="localhost"
DEFAULT_PORT="8001"
DEFAULT_LISTENERS="3"
DEFAULT_DURATION_MIN="30"
DEFAULT_DURATION_MAX="120"

# Show help
show_help() {
    cat << 'EOF'
Fake Listener Generator for Icecast Testbed

WARNING: FOR DEVELOPMENT AND TESTING ONLY

This script creates simulated listeners that connect to icecast test streams.
Each listener connects for a random duration, then disconnects naturally.
Use this to verify the radiostats agent correctly tracks listener counts.

USAGE:
    ./fake-listeners.sh [OPTIONS] [COMMAND]

COMMANDS:
    start     Start fake listeners (default if no command given)
    stop      Stop all running fake listeners
    status    Show how many fake listeners are currently running
    help      Show this help message

OPTIONS:
    -h, --host HOST         Icecast hostname (default: localhost)
    -p, --port PORT         Icecast port (default: 8001)
    -n, --listeners NUM     Listeners per mount (default: 3)
    --min SECONDS           Minimum listener duration (default: 30)
    --max SECONDS           Maximum listener duration (default: 120)

EXAMPLES:
    # Start with defaults (3 listeners per mount, 30-120s duration)
    ./fake-listeners.sh

    # Start 5 listeners per mount with shorter durations
    ./fake-listeners.sh -n 5 --min 10 --max 30

    # Connect to a different host/port
    ./fake-listeners.sh -h 192.168.1.100 -p 8000

    # Check current status
    ./fake-listeners.sh status

    # Stop all listeners
    ./fake-listeners.sh stop

VERIFYING LISTENERS:
    After starting fake listeners, verify they appear in icecast:

    # Quick check via admin stats
    curl -u admin:hackme http://localhost:8001/admin/stats | grep listeners

    # Run the agent test to see listener counts
    ./test-agent.sh ./config.dev.yml.example

NOTES:
    - Listeners connect to all 6 test mounts (mp3, ogg, aac, opus)
    - Each listener has a random duration within the min/max range
    - Listeners disconnect naturally when their duration expires
    - The script prevents multiple instances from running simultaneously
EOF
}

# Check if any listeners from PID file are still running
count_running_listeners() {
    if [ ! -f "$PID_FILE" ]; then
        echo 0
        return
    fi

    local running=0
    while read -r pid; do
        if kill -0 "$pid" 2>/dev/null; then
            running=$((running + 1))
        fi
    done < "$PID_FILE"
    echo "$running"
}

check_running_listeners() {
    local count
    count=$(count_running_listeners)
    [ "$count" -gt 0 ]
}

# Handle commands and options
HOST="$DEFAULT_HOST"
PORT="$DEFAULT_PORT"
LISTENERS_PER_MOUNT="$DEFAULT_LISTENERS"
DURATION_MIN="$DEFAULT_DURATION_MIN"
DURATION_MAX="$DEFAULT_DURATION_MAX"
COMMAND="start"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -n|--listeners)
            LISTENERS_PER_MOUNT="$2"
            shift 2
            ;;
        --min)
            DURATION_MIN="$2"
            shift 2
            ;;
        --max)
            DURATION_MAX="$2"
            shift 2
            ;;
        start|stop|status|help|--help)
            COMMAND="${1#--}"  # Remove -- prefix if present
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$0 help' for usage information."
            exit 1
            ;;
    esac
done

# Handle help command
if [ "$COMMAND" = "help" ]; then
    show_help
    exit 0
fi

# Handle status command
if [ "$COMMAND" = "status" ]; then
    count=$(count_running_listeners)
    if [ "$count" -gt 0 ]; then
        echo "Fake listeners running: $count"
        echo "PID file: $PID_FILE"
    else
        echo "No fake listeners currently running."
    fi
    exit 0
fi

# Handle stop command
if [ "$COMMAND" = "stop" ]; then
    if [ -f "$PID_FILE" ]; then
        echo "Stopping fake listeners..."
        stopped=0
        while read -r pid; do
            if kill "$pid" 2>/dev/null; then
                stopped=$((stopped + 1))
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
        echo "Stopped $stopped fake listener(s)."
    else
        echo "No fake listeners running (no PID file found)."
    fi
    exit 0
fi

BASE_URL="http://${HOST}:${PORT}"

# Mounts to listen to
MOUNTS=(
    "test-128.mp3"
    "test-64.mp3"
    "test.ogg"
    "test-128.aac"
    "test-48.aac"
    "test.opus"
)

echo "=== Fake Listener Generator ==="
echo ""
echo "WARNING: FOR DEVELOPMENT AND TESTING ONLY"
echo ""
echo "Target: ${BASE_URL}"
echo "Listeners per mount: ${LISTENERS_PER_MOUNT}"
echo "Duration range: ${DURATION_MIN}-${DURATION_MAX}s"
echo ""

# Check if listeners are already running
if check_running_listeners; then
    echo "FAIL: Fake listeners are already running."
    echo "      Run '$0 stop' first, or wait for them to finish."
    exit 1
fi

# Clean up stale PID file if no listeners running
rm -f "$PID_FILE"

# Check icecast is responding
if ! curl -sf "${BASE_URL}/status-json.xsl" > /dev/null 2>&1; then
    echo "FAIL: Icecast not responding at ${BASE_URL}"
    exit 1
fi

# Function to spawn a listener with random duration
spawn_listener() {
    local mount="$1"
    local listener_id="$2"
    local url="${BASE_URL}/${mount}"

    # Random duration between min and max
    local duration=$((DURATION_MIN + RANDOM % (DURATION_MAX - DURATION_MIN + 1)))

    # Spawn curl in background, downloading to /dev/null
    curl -s --max-time "$duration" "$url" > /dev/null 2>&1 &
    local pid=$!
    echo "$pid" >> "$PID_FILE"
    echo "  Started listener #${listener_id} on /${mount} (PID: ${pid}, duration: ${duration}s)"
}

echo "Starting listeners..."
echo ""

listener_count=0
for mount in "${MOUNTS[@]}"; do
    for i in $(seq 1 "$LISTENERS_PER_MOUNT"); do
        listener_count=$((listener_count + 1))
        spawn_listener "$mount" "$listener_count"
    done
done

echo ""
echo "=== ${listener_count} fake listeners started ==="
echo ""
echo "Listeners will disconnect naturally after their random duration expires."
echo ""
echo "To verify listeners are connected:"
echo "  curl -s http://${HOST}:${PORT}/status-json.xsl | grep -o '\"listeners\":[0-9]*'"
echo ""
echo "To stop all listeners immediately:"
echo "  $0 stop"
echo ""
echo "To check status:"
echo "  $0 status"
