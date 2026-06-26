# miniserver — Homelab Docker Stack

Self-hosted services running on `miniserver` (`192.168.1.167`) using Docker Compose with `include` for modular service management.

## Architecture

### Networks

| Network | Subnet | Internal | Purpose |
|---|---|---|---|
| `main` | 172.18.0.0/16 | | Legacy services (pihole, DUMB) |
| `ingress` | 172.20.0.0/24 | | nginx-proxy-manager only |
| `apps` | 172.20.1.0/24 | | User-facing web apps |
| `admin` | 172.20.2.0/24 | | Management tools |
| `monitoring` | 172.20.3.0/24 | | Monitoring stack |
| `internal-db` | 172.20.4.0/24 | yes | Databases, no external access |

Services are segmented by network — a compromised web app on `apps` cannot reach Portainer, Duplicati, or databases.

### Key services

**Core:** nginx-proxy-manager, portainer, homepage, pihole, cloudflare-ddns
**Apps:** homeassistant, paperless-ngx, firefly-iii, actualbudget, it-tools, speedtest-tracker
**Admin:** portainer, duplicati
**Monitoring:** uptime-kuma, beszel, netdata, dozzle, diun
**Media (disabled):** DUMB, plex, overseerr, tautulli

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

- Service configs: `compose/`
- Persistent data: `appdata/` (gitignored)
- Backups: `backups/`
- Environment: `.env` (gitignored) — copy from `.env.example`

## Access

- **Local:** `http://miniserver:<port>` or `http://192.168.1.167:<port>`
- **Remote:** Cloudflare tunnel + domains (`*.nicoshomelab.com`)
- **VPN:** Tailscale (`100.76.166.26`)
- **DNS:** Pi-hole at `192.168.1.167` — local records (`*.home`) resolve inside the LAN
- **Dashboard:** Homepage at `http://miniserver:3000`
