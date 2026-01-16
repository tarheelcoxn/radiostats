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

This testbed creates an icecast server with 6 test mounts, each streaming a unique frequency tone. The radiostats agent can query this instance to test data collection.

### Test Mounts

| Mount | Frequency | Format | Bitrate |
|-------|-----------|--------|---------|
| `/test-128.mp3` | 440Hz (A4) | MP3 | 128kbps |
| `/test-64.mp3` | 523Hz (C5) | MP3 | 64kbps |
| `/test.ogg` | 659Hz (E5) | Vorbis | q5 |
| `/test-128.aac` | 784Hz (G5) | AAC | 128kbps |
| `/test-48.aac` | 880Hz (A5) | AAC | 48kbps |
| `/test.opus` | 988Hz (B5) | Opus | 64kbps |

---

## Platform Options

Choose the deployment method that matches your environment:

| Platform | Directory | Best For |
|----------|-----------|----------|
| **Docker** | `docker/` | Any OS with Docker installed |
| **Native Debian/Ubuntu** | `native/` | Bare metal or VMs |
| **Lima (macOS)** | `lima/` | macOS development |

---

## Quick Start: Docker (Recommended)

The simplest option for any platform with Docker installed.

```bash
cd deploy/dev-testbed/docker
docker compose up -d
```

Verify it's working:
```bash
curl http://localhost:8001/status-json.xsl
```

Stop:
```bash
docker compose down
```

---

## Quick Start: Native Debian/Ubuntu

For direct installation on Debian 13 (trixie) or Ubuntu 24.04+.

```bash
# Install packages
sudo apt update
sudo apt install -y icecast2 ffmpeg

# Run provisioning script
sudo ./native/provision.sh
```

Icecast will be available at `http://localhost:8000/`.

---

## Quick Start: Lima (macOS)

For macOS users using Lima for Linux VMs.

```bash
cd deploy/dev-testbed/lima
limactl create --name=icecast-dev icecast-dev.yaml
limactl start icecast-dev

# Run provisioning inside the VM
limactl shell icecast-dev -- sudo bash /path/to/deploy/dev-testbed/native/provision.sh
```

Icecast will be available at `http://localhost:8001/` (port forwarded).

---

## Testing

### Verify Icecast is Running

```bash
./test/test-icecast.sh localhost 8001
```

This checks:
1. Icecast responds to HTTP requests
2. All 6 expected mounts are active
3. Each mount is streaming audio data

### Verify Agent Integration

```bash
./test/test-agent.sh ./config.dev.yml.example
```

This checks:
1. Agent can query icecast admin stats
2. XML response parses correctly
3. Data extraction works for listeners and bitrate

### Manual Verification

```bash
# Check server status (JSON)
curl http://localhost:8001/status-json.xsl

# Check admin stats (XML) - requires auth
curl -u admin:hackme http://localhost:8001/admin/stats

# Test audio playback
ffplay http://localhost:8001/test-128.mp3
```

---

## Configure Radiostats Agent

Copy `config.dev.yml.example` to your working `config.yml`:

```yaml
agent:
  icecast:
    hostname: 'localhost'
    port: 8001  # or 8000 for native installs
    username: 'admin'
    password: 'hackme'
```

Use `mounts.dev.yml` as your mount mapping file.

---

## Directory Structure

```
deploy/dev-testbed/
├── README.md                 # This file
├── icecast.xml               # Shared: Icecast server config
├── mounts.dev.yml            # Shared: Mount mappings for agent
├── config.dev.yml.example    # Shared: Example agent config
│
├── docker/                   # Docker deployment
│   ├── docker-compose.yml
│   ├── Dockerfile.icecast
│   └── entrypoint.sh
│
├── native/                   # Native Debian/Ubuntu
│   ├── provision.sh
│   └── icecast-source@.service
│
├── lima/                     # Lima (macOS)
│   └── icecast-dev.yaml
│
└── test/                     # Test harness
    ├── test-icecast.sh
    └── test-agent.sh
```

---

## Credentials (DEV ONLY)

| Service | Username | Password |
|---------|----------|----------|
| Icecast admin | `admin` | `hackme` |
| Icecast source | `source` | `hackme` |

**These credentials are intentionally weak. Do not use in production.**
