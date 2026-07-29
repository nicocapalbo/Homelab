# miniserver — Homelab Docker Stack

Self-hosted services running on a single host using Docker Compose with `include` for modular service management.

## Architecture

### Networks

| Network | Subnet | Internal | Purpose |
|---|---|---|---|
| `main` | 172.18.0.0/16 | | Legacy services |
| `ingress` | 172.20.0.0/24 | | nginx-proxy-manager only |
| `apps` | 172.20.1.0/24 | | User-facing web apps |
| `admin` | 172.20.2.0/24 | | Management tools |
| `monitoring` | 172.20.3.0/24 | | Monitoring stack |
| `internal-db` | 172.20.4.0/24 | yes | Databases, no external access |

Services are segmented by network — a compromised web app on `apps` cannot reach Portainer, Duplicati, or databases.

### Key services

**Core:** nginx-proxy-manager, portainer, homepage, pihole
**Apps:** homeassistant, paperless-ngx, firefly-iii, actualbudget, it-tools, speedtest-tracker
**Admin:** portainer, duplicati
**Monitoring:** uptime-kuma, beszel, netdata, dozzle, diun
**Media (disabled):** DUMB, plex, overseerr, tautulli

Secrets and service configs are stored in a [private config overlay](https://github.com/nicocapalbo/Homelab-private) repo.

### Restore from scratch

```bash
git clone git@github.com:nicocapalbo/Homelab.git
cd Homelab
bash restore.sh
```

This clones the private config overlay, copies `.env`, syncs `appdata/` configs, and automatically starts the stack.

### Sync config changes back

After configuring services through their UIs, save the state to the private repo:

```bash
bash sync-private.sh
```

This copies `.env` and all config files from `appdata/` into `../Homelab-private/`, commits, and pushes.

## Folder structure

```
.
├── compose/              # Service compose files (one per service or group)
│   ├── DUMB.yml
│   ├── wizarr.yml
│   ├── firefly/
│   │   ├── firefly.yml
│   │   └── .env
│   ├── paperlessngx/
│   │   ├── paperlessngx.yml
│   │   └── docker-compose.env
│   └── ...
├── appdata/              # Persistent service data (gitignored)
├── backups/              # Local backups (gitignored)
├── docker-compose.yaml   # Entry point — includes all service files
├── .env                  # Environment variables (gitignored)
├── restore.sh             # Bootstrap stack from private config overlay
├── sync-private.sh        # Sync configs back to private repo
└── README.md
```

## Setup

```bash
# 1. Clone the repo
git clone <repo-url>
cd homelab

# 2. Copy and configure environment
cp .env.example .env
# Edit .env with your API keys, tokens, and preferences

# 3. Start everything
docker compose up -d

# 4. Check that services are running
docker compose ps
```

## Managing services

### Enable / disable a service

Services are loaded via `include` in `docker-compose.yaml`. To toggle a service, edit that file and comment/uncomment its include line:

```yaml
include:
  - compose/wizarr.yml        # enabled
  # - compose/overseerr.yml   # disabled — uncomment to enable
```

Then run `docker compose up -d` to apply.

### Add a new service

1. Create a compose file in `compose/`, e.g. `compose/myapp.yml`
2. Add it to the `include` list in `docker-compose.yaml`
3. Add any needed env vars to `.env` and `.env.example`
4. Run `docker compose up -d myapp`

## Quick reference

```bash
# Start everything
docker compose up -d

# Start specific service
docker compose up -d portainer

# View logs
docker compose logs -f nginx

# Recreate a single service after config change
docker compose up -d homepage

# Stop everything
docker compose down
```

## Data & config

- Service compose files: `compose/`
- Persistent data: `appdata/` (gitignored)
- Backups: `backups/`
- Environment: `.env` (gitignored) — copy from `.env.example`
