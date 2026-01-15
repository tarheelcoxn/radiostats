#!/bin/bash
#
# Icecast development testbed provisioning script
#
# WARNING: FOR DEVELOPMENT AND TESTING ONLY
# DO NOT USE IN PRODUCTION
#
# This script:
# 1. Installs icecast configuration
# 2. Creates FFmpeg streaming scripts for 6 test mounts
# 3. Sets up systemd services
# 4. Starts everything
#
# Run as root inside the Lima VM.

set -euo pipefail

# Detect script directory (works when run via absolute path)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="/opt/icecast-sources"
ICECAST_PASSWORD="hackme"
ICECAST_HOST="localhost"
ICECAST_PORT="8000"

echo "=== Icecast Development Testbed Provisioning ==="
echo ""
echo "WARNING: FOR DEVELOPMENT AND TESTING ONLY"
echo ""

# Check we're running as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check required files exist
if [[ ! -f "$SCRIPT_DIR/icecast.xml" ]]; then
    echo "Error: $SCRIPT_DIR/icecast.xml not found. Is the Lima mount working?"
    exit 1
fi

echo "[1/5] Installing icecast configuration..."
cp "$SCRIPT_DIR/icecast.xml" /etc/icecast2/icecast.xml
chown icecast2:icecast /etc/icecast2/icecast.xml
chmod 640 /etc/icecast2/icecast.xml

# Enable icecast in default config (Debian disables it by default)
sed -i 's/ENABLE=false/ENABLE=true/' /etc/default/icecast2 2>/dev/null || true

echo "[2/5] Creating FFmpeg source scripts directory..."
mkdir -p "$SOURCE_DIR"

echo "[3/5] Creating FFmpeg streaming scripts..."

# Mount configuration: name, frequency, format args
# Each mount gets a unique musical note frequency
declare -A MOUNTS=(
    ["test-128-mp3"]="440:libmp3lame:-b:a 128k:audio/mpeg:mp3"
    ["test-64-mp3"]="523:libmp3lame:-b:a 64k:audio/mpeg:mp3"
    ["test-ogg"]="659:libvorbis:-q:a 5:audio/ogg:ogg"
    ["test-128-aac"]="784:aac:-b:a 128k:audio/aac:adts"
    ["test-48-aac"]="880:aac:-b:a 48k:audio/aac:adts"
    ["test-opus"]="988:libopus:-b:a 64k:audio/ogg:ogg"
)

for mount_name in "${!MOUNTS[@]}"; do
    IFS=':' read -r freq codec bitrate_args content_type format <<< "${MOUNTS[$mount_name]}"

    # Convert mount name to URL path (replace - with . for the actual mount point)
    # test-128-mp3 -> test-128.mp3
    url_mount=$(echo "$mount_name" | sed 's/-\([^-]*\)$/.\1/')

    script_path="$SOURCE_DIR/${mount_name}.sh"

    cat > "$script_path" << SCRIPT
#!/bin/bash
#
# FFmpeg source for /$url_mount (${freq}Hz tone)
#
# WARNING: FOR DEVELOPMENT AND TESTING ONLY
#
exec ffmpeg -hide_banner -loglevel warning \\
    -re -f lavfi -i "sine=frequency=${freq}:sample_rate=44100" \\
    -c:a ${codec} ${bitrate_args} \\
    -content_type "${content_type}" \\
    -f ${format} "icecast://source:${ICECAST_PASSWORD}@${ICECAST_HOST}:${ICECAST_PORT}/${url_mount}"
SCRIPT

    chmod +x "$script_path"
    echo "  Created: $script_path -> /$url_mount (${freq}Hz)"
done

echo "[4/5] Installing systemd service template..."
cp "$SCRIPT_DIR/icecast-source@.service" /etc/systemd/system/
systemctl daemon-reload

echo "[5/5] Enabling and starting services..."

# Start icecast first
systemctl enable icecast2
systemctl restart icecast2

# Wait for icecast to be ready
echo "  Waiting for icecast to start..."
sleep 3

# Enable and start all source services
for mount_name in "${!MOUNTS[@]}"; do
    systemctl enable "icecast-source@${mount_name}.service"
    systemctl start "icecast-source@${mount_name}.service"
    echo "  Started: icecast-source@${mount_name}.service"
done

echo ""
echo "=== Provisioning complete ==="
echo ""
echo "Icecast is running on port $ICECAST_PORT"
echo ""
echo "Test mounts available:"
for mount_name in "${!MOUNTS[@]}"; do
    url_mount=$(echo "$mount_name" | sed 's/-\([^-]*\)$/.\1/')
    echo "  http://localhost:${ICECAST_PORT}/${url_mount}"
done
echo ""
echo "Admin interface: http://localhost:${ICECAST_PORT}/admin/"
echo "  Username: admin"
echo "  Password: $ICECAST_PASSWORD"
echo ""
echo "To verify from macOS host:"
echo "  curl http://localhost:${ICECAST_PORT}/status.xsl"
echo "  curl -u admin:${ICECAST_PASSWORD} http://localhost:${ICECAST_PORT}/admin/stats"
