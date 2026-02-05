# SmokePing Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/sistemasminorisa/smokeping.svg)](https://hub.docker.com/r/sistemasminorisa/smokeping)

A production-ready SmokePing Docker image with a modern web interface, integrated traceroute with historical data, and Telegram alerts for network events.

Built by [everyWAN](https://everywan.com). Based on the excellent [linuxserver/smokeping](https://hub.docker.com/r/linuxserver/smokeping) image.

---

## Why this image exists

We've been running SmokePing for years to monitor latency and packet loss across our network infrastructure. SmokePing itself is fantastic — Tobi Oetiker created an incredibly powerful tool that has stood the test of time.

But we kept hitting the same frustrations:

- The default web interface looks dated and isn't responsive
- There's no built-in way to see traceroute history (where was the route yesterday?)
- Setting up alerts requires digging through documentation
- Deploying across multiple locations means manual configuration on each node

So we fixed it. We wrote custom scripts, built a modern frontend, added traceroute history with a year of retention, and packaged everything into a single Docker image.

We've been using this in production for years. Now we're sharing it.

---

## What you get

**Modern Web Interface**

The frontend is completely redesigned. Responsive layout, clean navigation, works on mobile. All the SmokePing functionality you know, with a UI that doesn't feel like 2005.

**Traceroute History**

Every target gets a traceroute panel. Not just the current route — you can see the full history. Filter by date, by hour, see exactly when the route changed. The daemon runs every 5 minutes and keeps 365 days of data by default.

**Telegram Alerts**

Real-time notifications when something goes wrong:

- Packet loss (configurable thresholds: warning vs critical)
- Latency spikes (sudden RTT increases)
- Route changes (when your upstream provider actually changes, not just internal load balancing)

The route change detection is smart. It understands that `router1.telia.net` and `router2.telia.net` are the same provider. It only alerts when the actual carrier changes.

**Multi-Location Monitoring**

Deploy a master and multiple slaves across different locations. Each slave runs its own traceroute daemon with local history. The master aggregates all the latency data. Monitor your network from NYC, London, Tokyo — all in one dashboard.

**Full Customization**

Change the logo, colors, company name, all via environment variables. No need to rebuild the image or edit files inside the container.

---

## Quick Start

Pull the image and run:

```bash
docker run -d \
  --name smokeping \
  -p 80:80 \
  --cap-add NET_RAW \
  --cap-add NET_ADMIN \
  -v $(pwd)/config:/config \
  -v $(pwd)/data:/data \
  -e TZ=Europe/Madrid \
  sistemasminorisa/smokeping:latest
```

Open `http://localhost` and you're monitoring.

The image includes example targets (major CDN providers, DNS servers, etc.) so you can see it working immediately. Replace them with your own infrastructure.

---

## Docker Compose

For a proper deployment:

```yaml
version: '3.8'

services:
  smokeping:
    image: sistemasminorisa/smokeping:latest
    container_name: smokeping
    ports:
      - "80:80"
    cap_add:
      - NET_RAW
      - NET_ADMIN
    volumes:
      - ./config:/config
      - ./data:/data
    environment:
      - TZ=Europe/Madrid
      - PUID=1000
      - PGID=1000
      # Telegram alerts (optional)
      - TELEGRAM_BOT_TOKEN=your_bot_token
      - TELEGRAM_CHAT_ID=your_chat_id
      # Branding (optional)
      - SMOKEPING_LOGO_URL=https://your-company.com/logo.png
      - SMOKEPING_BRAND_NAME=Your Company
      - SMOKEPING_BRAND_URL=https://your-company.com
      - SMOKEPING_COLOR_SIDEBAR_BG=#1a1a2e
      - SMOKEPING_TITLE=Network Monitor
      - SMOKEPING_OWNER=NOC Team
    restart: unless-stopped
```

We've included several compose files for different scenarios:

| File | Description |
|------|-------------|
| `docker-compose.yml` | Standalone deployment, port 80 |
| `docker-compose.swarm.yml` | Docker Swarm mode |
| `docker-compose.traefik.yml` | Behind existing Traefik proxy |
| `docker-compose.full-stack.yml` | Includes Traefik v3 |
| `docker-compose.slave.yml` | Slave instance for multi-location |

---

## Configuring Targets

Targets live in `config/Targets`. The format is standard SmokePing:

```ini
*** Targets ***
probe = FPing
menu = Top
title = Network Monitor
remark = Latency and packet loss monitoring

+Production
menu = Production
title = Production Infrastructure

++WebServers
menu = Web Servers
title = Web Server Cluster

+++Primary
menu = Primary
title = Primary Web Server
host = web1.example.com
alerts = bigloss,someloss,rttdetect

+++Secondary
menu = Secondary
title = Secondary Web Server
host = web2.example.com
alerts = bigloss,someloss,rttdetect

++Databases
menu = Databases
title = Database Servers

+++PostgreSQL
menu = PostgreSQL
title = PostgreSQL Primary
host = db.example.com
traceroute_mode = tcp
alerts = bigloss,someloss
```

The hierarchy creates the navigation menu. Use `+` for categories, `++` for subcategories, `+++` for targets.

---

## Configuring Alerts

Alerts are defined in `config/Alerts`:

```ini
*** Alerts ***
to = |/usr/share/webapps/smokeping/telegram_notify.pl
from = smokeping@localhost

+bigloss
type = loss
pattern = ==0%,==0%,==0%,==0%,>0%,>0%,>0%
comment = Packet loss detected (critical)

+someloss
type = loss
pattern = >0%,*12*,>0%,*12*,>0%
comment = Intermittent packet loss

+rttdetect
type = rtt
pattern = <100,<100,<100,<100,<100,<150,>150,>150,>150
comment = Latency spike detected

+startloss
type = loss
pattern = ==S,==U
comment = Service appears unreachable
```

Assign alerts to targets with:

```ini
++MyServer
host = server.example.com
alerts = bigloss,someloss,rttdetect
```

For Telegram notifications, set the environment variables `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`.

---

## Traceroute Modes

By default, traceroute uses ICMP. For hosts behind strict firewalls, you can change the mode per target:

```ini
++FirewalledServer
host = server.example.com
traceroute_mode = tcp
```

| Mode | Protocol | When to use |
|------|----------|-------------|
| `icmp` | ICMP Echo | Default, works most places |
| `udp` | UDP | When ICMP is blocked |
| `tcp` | TCP SYN | For hosts behind strict firewalls |

---

## Multi-Location Setup

To monitor from multiple geographic locations:

**1. Deploy the Master**

Use `docker-compose.yml` as normal. Configure your targets and alerts.

**2. Register Slaves on the Master**

Edit `config/Slaves`:

```ini
*** Slaves ***
secrets=/config/smokeping_secrets

+nyc-slave
display_name = New York
location = New York, USA
color = 00ff00

+london-slave
display_name = London
location = London, UK
color = 0000ff
```

Add shared secrets to `config/smokeping_secrets`:

```
nyc-slave:your_secret_key_nyc
london-slave:your_secret_key_london
```

**3. Deploy Slaves**

Use `docker-compose.slave.yml` at each location:

```yaml
environment:
  - MASTER_URL=https://master.example.com/smokeping/smokeping.cgi
  - SHARED_SECRET=your_secret_key_nyc
  - CACHE_DIR=/var/lib/smokeping
```

**4. Assign Slaves to Targets**

In `config/Targets` on the master:

```ini
+Production
menu = Production
title = Production Servers
slaves = nyc-slave london-slave

++WebServer
host = web.example.com
```

Each slave will probe the targets assigned to it and send results to the master.

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TZ` | Timezone | `UTC` |
| `PUID` | User ID | `1000` |
| `PGID` | Group ID | `1000` |
| `TELEGRAM_BOT_TOKEN` | Bot token from @BotFather | — |
| `TELEGRAM_CHAT_ID` | Chat or channel ID | — |
| `SMOKEPING_LOGO_URL` | Logo image URL | `images/smokeping.png` |
| `SMOKEPING_BRAND_NAME` | Company name in footer | — |
| `SMOKEPING_BRAND_URL` | Company website | — |
| `SMOKEPING_COLOR_SIDEBAR_BG` | Sidebar color (hex) | `#233350` |
| `SMOKEPING_TITLE` | Page title | `SmokePing` |
| `SMOKEPING_OWNER` | Owner name | `SmokePing Admin` |
| `SMOKEPING_CONTACT` | Contact email | — |
| `TRACEPING_INTERVAL` | Traceroute interval in seconds | `300` |
| `TRACEPING_RETENTION_DAYS` | Days to keep traceroute history | `365` |
| `MASTER_URL` | Master URL (slave mode only) | — |
| `SHARED_SECRET` | Shared secret (slave mode only) | — |
| `CACHE_DIR` | Cache directory (slave mode only) | — |

---

## Troubleshooting

**RRD file not found errors on first run**

This is normal. SmokePing creates RRD files after the first probe cycle, which takes about 5 minutes.

**Logo not showing**

Make sure `SMOKEPING_LOGO_URL` points to an accessible URL. For local files, mount them and use a path like `/config/logo.png`.

**Traceroute panel empty**

Check that the container has NET_RAW and NET_ADMIN capabilities. Look at the container logs for traceroute daemon errors.

**Slave not connecting to master**

Verify `MASTER_URL` is correct and accessible from the slave. Check that the secret matches in both `config/smokeping_secrets` on the master and `SHARED_SECRET` on the slave.

---

## Credits

This image wouldn't exist without the work of others:

- [Tobi Oetiker](https://oss.oetiker.ch/smokeping/) for creating SmokePing
- [LinuxServer.io](https://www.linuxserver.io/) for the excellent base Docker image
- The open source community for countless tools and libraries

---

## Contributing

Found a bug? Want to add a feature? Pull requests are welcome.

[GitHub Repository](https://github.com/everywan-dev/smokeping)

---

## License

MIT License. See LICENSE file.

---

Built and maintained by [everyWAN](https://everywan.com)
