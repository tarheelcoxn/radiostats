# Parallels VM for Docker Deployment Testing

This directory contains scripts and documentation for testing the radiostats Docker deployment on native Linux using Parallels Desktop.

## Overview

- **VM OS**: Debian 13 (trixie)
- **Purpose**: Validate Docker deployment on native Linux before production
- **Host Integration**: Shared folder for easy code iteration

---

## VM Setup

### 1. Download Debian 13 ISO

Choose the correct architecture for your Mac:

**Apple Silicon (M1/M2/M3/M4)** - use ARM64:
- https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/
- Direct: https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-13.3.0-arm64-netinst.iso

**Intel Mac** - use AMD64:
- https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/
- Direct: https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.3.0-amd64-netinst.iso

### 2. Create the VM in Parallels

1. Open Parallels Desktop
2. File > New > Install Windows or another OS from a DVD or image file
3. Select the Debian ISO
4. Configure the VM:
   - **Name**: `radiostats-docker-test`
   - **CPU**: 2 cores
   - **RAM**: 4096 MB
   - **Disk**: 40 GB

### 3. Install Debian

During installation:
- Choose minimal installation (no desktop environment needed)
- Create a user (e.g., `debian`)
- Enable SSH server when prompted for software selection
- Skip other optional components to keep it lightweight

### 4. Install Parallels Tools

After Debian boots:

```bash
# Mount the tools ISO (Actions > Install Parallels Tools in Parallels menu)
sudo mkdir -p /mnt/cdrom
sudo mount /dev/cdrom /mnt/cdrom

# Install dependencies and tools
sudo apt-get update
sudo apt-get install -y build-essential linux-headers-$(uname -r)
sudo /mnt/cdrom/install --install-unattended-with-deps

# Reboot
sudo reboot
```

### 5. Configure Shared Folder

In Parallels VM settings:
1. Go to Hardware > Shared Folders
2. Add a shared folder:
   - **Source**: `/Users/cmpalmer/radiostats`
   - **Name**: `radiostats`
3. Enable "Share all Mac disks with Linux" OR add specific folder

The shared folder will be available at `/media/psf/radiostats` after reboot.

### 6. Configure Port Forwarding

In Parallels VM settings:
1. Go to Hardware > Network
2. Click "Advanced Settings"
3. Add port forwarding rules:

| Host Port | Guest Port | Protocol | Description |
|-----------|------------|----------|-------------|
| 3080 | 3000 | TCP | Frontend |
| 8080 | 8000 | TCP | Backend |

---

## Provisioning

After VM setup, run the provision script to install Docker:

```bash
# Inside the VM
cd /media/psf/radiostats/radiostats/deploy/parallels
sudo ./provision.sh
```

Then log out and back in (or run `newgrp docker`) to activate the docker group.

---

## Testing Docker Deployment

Run the test deployment script:

```bash
# Inside the VM
cd /media/psf/radiostats/radiostats/deploy/parallels
./test-docker-deploy.sh
```

This will:
1. Create config files from examples (if needed)
2. Build all Docker images
3. Start the containers
4. Validate the services are responding

---

## Accessing Services

From your Mac:
- **Frontend**: http://localhost:3080
- **Backend Admin**: http://localhost:8080/admin/

From inside the VM:
- **Frontend**: http://localhost:3000
- **Backend Admin**: http://localhost:8000/admin/

---

## Cleanup

To stop the containers:
```bash
cd /media/psf/radiostats/radiostats
docker compose down
```

To remove all images and volumes:
```bash
docker compose down -v --rmi all
```

---

## Troubleshooting

### Shared folder not accessible

1. Verify Parallels Tools are installed: `lsmod | grep prl`
2. Check mount: `mount | grep psf`
3. Try remounting: `sudo mount -t prl_fs host /media/psf`

### Docker permission denied

Run `newgrp docker` or log out and back in after running provision.sh.

### Port forwarding not working

1. Verify containers are running: `docker compose ps`
2. Check the VM's firewall: `sudo iptables -L`
3. Verify port forwarding in Parallels VM settings

### Build fails with network errors

Ensure the VM has internet access:
```bash
ping -c 3 google.com
curl -I https://registry.hub.docker.com/
```
