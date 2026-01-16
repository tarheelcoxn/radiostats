#!/bin/bash
#
# Entrypoint for development icecast testbed container
#
# WARNING: FOR DEVELOPMENT AND TESTING ONLY
# DO NOT USE IN PRODUCTION
#
# Starts icecast2 and 6 FFmpeg processes generating test tones.

set -e

ICECAST_PASSWORD="hackme"
ICECAST_HOST="localhost"
ICECAST_PORT="8000"

echo "=== Starting Icecast Development Testbed ==="
echo ""
echo "WARNING: FOR DEVELOPMENT AND TESTING ONLY"
echo ""

# Start icecast in background
echo "Starting icecast2..."
/usr/bin/icecast2 -c /etc/icecast2/icecast.xml &
ICECAST_PID=$!

# Wait for icecast to be ready
echo "Waiting for icecast to start..."
sleep 3

# Check icecast is running
if ! kill -0 $ICECAST_PID 2>/dev/null; then
    echo "ERROR: Icecast failed to start"
    exit 1
fi

echo "Starting FFmpeg audio sources..."

# Mount configuration: name|frequency|codec|bitrate_args|content_type|format
declare -A MOUNTS=(
    ["test-128.mp3"]="440|libmp3lame|-b:a 128k|audio/mpeg|mp3"
    ["test-64.mp3"]="523|libmp3lame|-b:a 64k|audio/mpeg|mp3"
    ["test.ogg"]="659|libvorbis|-q:a 5|audio/ogg|ogg"
    ["test-128.aac"]="784|aac|-b:a 128k|audio/aac|adts"
    ["test-48.aac"]="880|aac|-b:a 48k|audio/aac|adts"
    ["test.opus"]="988|libopus|-b:a 64k|audio/ogg|ogg"
)

FFMPEG_PIDS=()

for mount_name in "${!MOUNTS[@]}"; do
    IFS='|' read -r freq codec bitrate_args content_type format <<< "${MOUNTS[$mount_name]}"

    echo "  Starting /$mount_name (${freq}Hz)"

    ffmpeg -hide_banner -loglevel warning \
        -re -f lavfi -i "sine=frequency=${freq}:sample_rate=44100" \
        -c:a ${codec} ${bitrate_args} \
        -content_type "${content_type}" \
        -f ${format} "icecast://source:${ICECAST_PASSWORD}@${ICECAST_HOST}:${ICECAST_PORT}/${mount_name}" &

    FFMPEG_PIDS+=($!)
done

echo ""
echo "=== Testbed Running ==="
echo ""
echo "Icecast: http://localhost:${ICECAST_PORT}/"
echo "Admin:   http://localhost:${ICECAST_PORT}/admin/ (admin:hackme)"
echo ""
echo "Test mounts:"
for mount_name in "${!MOUNTS[@]}"; do
    echo "  http://localhost:${ICECAST_PORT}/${mount_name}"
done
echo ""

# Handle shutdown
cleanup() {
    echo "Shutting down..."
    for pid in "${FFMPEG_PIDS[@]}"; do
        kill $pid 2>/dev/null || true
    done
    kill $ICECAST_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

# Wait for icecast (main process)
wait $ICECAST_PID
