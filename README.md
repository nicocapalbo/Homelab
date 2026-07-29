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

## Getting started

Secrets and service configs are stored in a [private config overlay repo](https://github.com/nicocapalbo/Homelab-private). Two setup paths are available:

- **With access to the private repo** — full restore, one command
- **Without access** — manual cold start from `.env.example`

### With private repo access (restore from scratch)

```bash
# 1. Clone the public repo and enable auto-sync hooks
git clone git@github.com:nicocapalbo/Homelab.git
cd Homelab
git config core.hooksPath .githooks

# 2. Restore: clones private repo, copies .env, syncs configs, starts everything
bash restore.sh
```

### Without private repo access (cold start)

```bash
# 1. Clone the public repo
git clone git@github.com:nicocapalbo/Homelab.git
cd Homelab

# 2. Create and configure environment
cp .env.example .env
# Edit .env with your API keys, tokens, and preferences

# 3. Start everything
docker compose up -d
```

## Syncing config changes

After making changes through a service's UI, save them permanently:

```bash
bash sync-private.sh
```

This copies `.env` and all config files from `appdata/` into `../Homelab-private/`, commits, and pushes.

The pre-push hook also runs this automatically whenever you `git push` with unsaved changes.

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
├── .env.example          # Template for .env
├── restore.sh            # Bootstrap stack from private config overlay
├── sync-private.sh       # Sync configs back to private repo
├── AGENTS.md             # Instructions for AI coding agents
└── README.md
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
