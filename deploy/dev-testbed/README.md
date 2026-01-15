# Development Icecast Testbed

---

## WARNING: FOR DEVELOPMENT AND TESTING ONLY

This directory contains configuration and scripts for creating a **development-only** icecast instance with synthetic audio sources.

**DO NOT USE IN PRODUCTION.**

- Credentials are weak and meant for local testing
- Audio sources are synthetic test tones, not real content
- No security hardening has been applied

---

## Overview

This testbed creates a Lima VM running:
- Icecast2 server with 6 test mounts
- FFmpeg processes generating continuous test tones (different frequencies per mount)

The radiostats agent can query this icecast instance to test data collection without a real streaming setup.

## Mounts

| Mount | Frequency | Format | Bitrate |
|-------|-----------|--------|---------|
| `/test-128.mp3` | 440Hz (A4) | MP3 | 128kbps |
| `/test-64.mp3` | 523Hz (C5) | MP3 | 64kbps |
| `/test.ogg` | 659Hz (E5) | Vorbis | q5 |
| `/test-128.aac` | 784Hz (G5) | AAC | 128kbps |
| `/test-48.aac` | 880Hz (A5) | AAC | 48kbps |
| `/test.opus` | 988Hz (B5) | Opus | 64kbps |

Each mount plays a distinct musical note, making it easy to verify which stream you're hearing.

## Prerequisites

- [Lima](https://lima-vm.io/) installed on macOS
- Network access to download packages in the VM

## Quick Start

### 1. Create and start the VM

```bash
cd /path/to/radiostats/deploy/dev-testbed
limactl create --name=icecast-dev icecast-dev.yaml
limactl start icecast-dev
```

### 2. Run the provisioning script

```bash
limactl shell icecast-dev
# Inside the VM (adjust path to your radiostats checkout):
sudo /Users/$USER/radiostats/radiostats/deploy/dev-testbed/provision.sh
```

### 3. Verify icecast is running

From macOS (port 8000 is forwarded):
```bash
# Check server status
curl http://localhost:8000/status.xsl

# Check admin stats (XML)
curl -u admin:hackme http://localhost:8000/admin/stats
```

### 4. Test audio playback

```bash
# Play one of the mounts
ffplay http://localhost:8000/test-128.mp3
# or
vlc http://localhost:8000/test.ogg
```

## Configure radiostats agent

Copy `config.dev.yml.example` to your `config.yml` and adjust paths as needed. The key settings:

```yaml
agent:
  icecast:
    hostname: 'localhost'  # Lima forwards port 8000 to macOS
    port: 8000
    username: 'admin'
    password: 'hackme'
```

Use `mounts.dev.yml` as your `mounts.yml` for testing.

## Files in this directory

| File | Purpose |
|------|---------|
| `icecast-dev.yaml` | Lima VM configuration |
| `provision.sh` | Automated setup script (runs inside VM) |
| `icecast.xml` | Icecast server configuration template |
| `icecast-source@.service` | Systemd unit template for FFmpeg sources |
| `mounts.dev.yml` | Mount mapping for radiostats agent |
| `config.dev.yml.example` | Example agent configuration |

## Stopping and removing

```bash
# Stop the VM
limactl stop icecast-dev

# Remove the VM entirely
limactl delete icecast-dev
```

## Credentials (DEV ONLY)

| Service | Username | Password |
|---------|----------|----------|
| Icecast admin | `admin` | `hackme` |
| Icecast source | `source` | `hackme` |

**These credentials are intentionally weak. Do not use in production.**
