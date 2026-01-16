# Development Environment Setup

This document covers setting up a containerized development environment for radiostats.

## Status

| Platform | Status | Notes |
|----------|--------|-------|
| macOS (Lima) | Validated | Tested January 2026 |
| Debian 13 | Not yet tested | Planned |

## Known Gaps

- **config.yml**: ibiblio staff can reference production configs, but a sensible dev configuration is a work in progress
- **mounts.yml**: Same as above - production examples exist but dev setup not yet defined
- **Database initialization**: No instructions for initial schema setup or migrations
- **TLS/HTTPS and reverse proxy**: Not covered (dev only)

---

## Prerequisites

### macOS

Install via [Homebrew](https://brew.sh/):

```bash
brew install lima
```

Lima provides containerd and nerdctl (Docker-compatible container tools).

### Debian 13

- Docker and docker-compose, OR
- containerd and nerdctl

*(Debian 13 setup not yet validated)*

---

## Quick Start (macOS with Lima)

### 1. Create and start a Lima VM

```bash
limactl create --name=radiostats --cpus=4 --memory=4 --disk=100 template://debian
limactl start radiostats
```

### 2. Access the repository

Lima mounts your home directory automatically. If your repo is at `~/radiostats/radiostats`, it's available inside the VM at the same path.

```bash
limactl shell radiostats
cd ~/radiostats/radiostats
```

### 3. Create configuration files

You need two files in the repo root:
- `config.yml` - main application configuration
- `mounts.yml` - icecast mount mappings

**Note**: Sensible defaults for dev are a work in progress. Contact ibiblio staff for guidance based on production configs.

### 4. Build and start containers

```bash
nerdctl compose up -d --build
```

### 5. Verify containers are running

```bash
nerdctl ps
```

Expected containers:
- `radiostats-backend-1` (port 8000)
- `radiostats-frontend-1` (port 3000)
- `radiostats-agent-1`
- `radiostats-db-1`

### 6. Verify endpoints

```bash
curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/  # Frontend: expect 200
curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/admin/  # Backend: expect 302
```

---

## Quick Start (Debian 13)

*(Not yet validated. Expected to be similar to the Lima workflow using docker-compose or nerdctl directly.)*

---

## Common Commands

### Lima VM management

```bash
limactl list                    # List VMs
limactl start radiostats        # Start VM
limactl stop radiostats         # Stop VM
limactl shell radiostats        # Shell into VM
limactl delete radiostats       # Delete VM
```

### Container management (inside Lima or on Debian)

```bash
nerdctl compose up -d           # Start containers (detached)
nerdctl compose down            # Stop containers
nerdctl compose up -d --build   # Rebuild and start
nerdctl ps                      # List running containers
nerdctl logs --tail 20 <name>   # View container logs (limit output)
```

Replace `nerdctl` with `docker` if using Docker.

---

## Troubleshooting

### Agent shows DNS errors

Expected in isolated dev environments without access to icecast servers. The agent still completes its job cycle.

### Backend returns 404 at root

Expected. Django doesn't serve at `/`. Try `/admin/` instead.

### Viewing logs causes issues

Always limit log output:

```bash
nerdctl logs --tail 20 radiostats-backend-1
```

---

## Running Locally (without containers)

See [README.md](README.md) for instructions on running components directly using Python virtualenvs and npm.
