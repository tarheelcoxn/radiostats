#!/bin/bash
#
# provision.sh - Install Docker on Debian 13 (trixie) for radiostats testing
#
# Usage: sudo ./provision.sh
#
set -euo pipefail

# Check for root
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Detect the non-root user who invoked sudo
INSTALL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo '')}"
if [[ -z "$INSTALL_USER" || "$INSTALL_USER" == "root" ]]; then
    echo "ERROR: Could not determine non-root user. Run with: sudo ./provision.sh"
    exit 1
fi

echo "=== Radiostats Docker Provisioning for Debian 13 ==="
echo "Installing Docker for user: $INSTALL_USER"
echo ""

# Step 1: Update system and install prerequisites
echo "[1/5] Installing prerequisites..."
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    jq

# Step 2: Add Docker's official GPG key
echo "[2/5] Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Step 3: Add Docker repository
echo "[3/5] Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

# Step 4: Install Docker
echo "[4/5] Installing Docker..."
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Step 5: Configure user permissions
echo "[5/5] Configuring user permissions..."
usermod -aG docker "$INSTALL_USER"

# Start and enable Docker service
systemctl enable docker
systemctl start docker

echo ""
echo "=== Installation Complete ==="
echo ""

# Verify installation
echo "Docker version:"
docker --version
echo ""
echo "Docker Compose version:"
docker compose version
echo ""

echo "IMPORTANT: Log out and back in (or run 'newgrp docker') to use Docker without sudo."
echo ""
echo "Next steps:"
echo "  1. Log out and back in"
echo "  2. cd /media/psf/radiostats/radiostats/deploy/parallels"
echo "  3. ./test-docker-deploy.sh"
