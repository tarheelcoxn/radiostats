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
4. Name the VM `radiostats-docker-test`
5. Tick **Customize settings before installation**
6. In the settings window, configure:
   - **CPU**: 2 cores
   - **RAM**: 4096 MB
   - **Disk**: 40 GB minimum (a higher default value is fine)

### 3. Install Debian

During installation:
- Set a root password when prompted
- Create user **radiostats** when prompted for full name and username
- Set a password for the radiostats user
- When prompted for software selection, enable **SSH server** only
- Skip desktop environment and other optional components

After first boot, configure sudo for the radiostats user:

```bash
# Log in as root
su -

# Install sudo
apt-get update
apt-get install -y sudo

# Add radiostats user to sudo group
usermod -aG sudo radiostats

# Log out of root
exit

# Log out and back in as radiostats for sudo to take effect
```

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
   - **Source**: The directory containing the `radiostats` repository on your Mac
   - **Name**: `radiostats`
3. Enable "Share all Mac disks with Linux" OR add specific folder

The shared folder will be available at `/media/psf/radiostats` after reboot.

### 6. Configure Port Forwarding

Port forwarding is configured in Parallels Desktop Preferences (not per-VM settings):

1. In VM settings, go to **Hardware > Network**
2. Confirm network is set to **Shared Network (Recommended)**
3. Click **Advanced...**
4. Click **Open Network Preferences...**
5. In the **Port forwarding rules** section at the bottom, click **+** to add rules:

| Protocol | Source port | Forward to | Destination port |
|----------|-------------|------------|------------------|
| TCP | 3080 | radiostats-docker-test | 3000 |
| TCP | 8080 | radiostats-docker-test | 8000 |

For each rule:
- **Protocol**: TCP
- **Source port**: the Mac host port (3080 or 8080)
- **Forward to**: select the VM (`radiostats-docker-test`)
- **Destination port**: the guest port (3000 or 8000)
- Click **OK**

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
