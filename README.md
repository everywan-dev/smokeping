# SmokePing Docker - Custom Frontend, Traceroute & Telegram Alerts

[![Docker Pulls](https://img.shields.io/docker/pulls/sistemasminorisa/smokeping.svg)](https://hub.docker.com/r/sistemasminorisa/smokeping)
[![Docker Image](https://img.shields.io/badge/docker-image-blue.svg)](https://hub.docker.com/r/sistemasminorisa/smokeping)

**SmokePing** Docker image featuring a modern custom frontend, integrated **Traceroute**, and native **Telegram Alerts**. Based on [linuxserver/smokeping](https://hub.docker.com/r/linuxserver/smokeping).

## 🎯 Features

- ✅ **SmokePing 2.9.0** - Latest stable version
- ✅ **Modern Frontend** - Responsive and customized interface
- ✅ **Integrated Traceroute** - Live traceroute panel via internal API
- ✅ **Telegram Alerts** - Real-time notifications for Loss, Latency, and **Route Changes**
- ✅ **Full Customization** - Configurable Logo, Colors, and Branding via Environment Variables
- ✅ **Docker Swarm Ready** - Simplified deployment with Traefik support
- ✅ **Zero Code Configuration** - Frontend logic resides within the image, maintaining clean data persistence

## � How This Image Works

> **You don't need to clone this repository to use SmokePing!**

This is a **pre-configured SmokePing Docker image** ready to run. The image includes:
- A **custom modern frontend** with responsive design
- **Example targets** (major CDN providers, DNS servers, etc.) to get you started
- **Telegram alert scripts** for real-time notifications
- **Traceroute integration** for route monitoring

### Customizing for Your Brand

Simply use [`docker-compose.yml`](#1️⃣-standalone-localsingle-server) from Docker Hub and customize via **environment variables**:

```yaml
services:
  smokeping:
    image: sistemasminorisa/smokeping:latest
    environment:
      - SMOKEPING_LOGO_URL=https://your-company.com/logo.png
      - SMOKEPING_BRAND_NAME=Your Company
      - SMOKEPING_COLOR_SIDEBAR_BG=#1a1a2e
      - SMOKEPING_TITLE=Network Monitor
```

### Adding Your Own Targets

Targets are configured in a simple **volume-mounted file**. Just create your own `config/Targets` file:

```ini
*** Targets ***

+MyServers
menu = My Servers
title = Production Servers

++WebServer
menu = Web Server
title = Main Web Server
host = web.example.com
alerts = bigloss,someloss

++DatabaseServer
menu = Database
title = PostgreSQL Server
host = db.example.com
traceroute_mode = tcp
```

Mount it in your compose file:
```yaml
volumes:
  - ./config/Targets:/config/Targets:ro
```

> **The example targets in this repository** are demonstrations. Replace them with your own infrastructure!

## �🚀 Deployment Options

We have prepared 3 configurations ready to use depending on your environment:

### 1️⃣ Standalone (Local/Single Server)
Run directly (`docker-compose up`) exposing port 80.
- File: `docker-compose.yml`

```bash
docker-compose up -d
```

### 2️⃣ Docker Swarm (Basic)
Run in a Swarm cluster exposing port 80 on the node.
- File: `docker-compose.swarm.yml`

```bash
docker stack deploy -c docker-compose.swarm.yml smokeping
```

### 3️⃣ Docker Swarm + Existing Traefik (Recommended)
Run behind an *existing* Traefik proxy.
- File: `docker-compose.traefik.yml`

```bash
docker stack deploy -c docker-compose.traefik.yml smokeping
```

### 4️⃣ Full Stack (Swarm + Traefik Included)
Deploys both **Traefik v3** (latest) and Smokeping together. Ideal for fresh clusters.
- File: `docker-compose.full-stack.yml`

```bash
docker stack deploy -c docker-compose.full-stack.yml monitor
```
*(Access Smokeping via http://localhost or any node IP)*

## 🔔 Telegram Alerts System

This image includes a **Smart Alert System** that goes beyond basic ping monitoring. It integrates both native SmokePing alerts and a custom Daemon for route analysis.

### Available Alert Types
The system comes pre-configured with **4 defined alert patterns** in `config/Alerts`:

| Alert Name | Type | Sensitivity | Trigger Condition | Status Header |
| :--- | :--- | :--- | :--- | :--- |
| **`bigloss`** | Loss | **CRITICAL** | **100% Loss** for **3 cycles** (~15 min) | `🔴 CRITICAL ALERT` |
| **`someloss`** | Loss | **WARNING** | **Any Loss** for **2 cycles** | `⚠️ WARNING` |
| **`rttdetect`** | Latency | **WARNING** | Sudden **Latency Spike** (>10ms increase) | `⚠️ WARNING` |
| **`startloss`** | Loss | **WARNING** | Loss detected immediately at startup | `⚠️ WARNING` |
| **(Route)** | Trace | **INFO** | **Significant Path Change** detected | `⚠️ Route Change Detected` |

> **Note:** Route Change alerts are **Always Active** and global. Loss/Latency alerts must be assigned to targets.

### How to Enable Alerts (Important)
To enable alerts for a target, you must add the `alerts` line to the target definition in `config/Targets`.

**✅ CORRECT Usage (Per Target or Group):**
```ini
++MyCriticalServer
menu = Critical Server
title = Critical Server IP
host = 1.2.3.4
alerts = bigloss,someloss,rttdetect,startloss
```

**❌ INCORRECT Usage (Do NOT do this):**
Do **NOT** add `alerts = ...` to the root `*** Targets ***` section. This causes startup errors due to configuration parsing order. Always apply it to Groups (e.g., `+EmEA`) or specific Targets.

### Configuration
Simply add these environment variables to your compose file:

```yaml
    environment:
      - TELEGRAM_BOT_TOKEN=123456789:AbCdeWgHiJkLmNoPqRsTuVwXyZ
      - TELEGRAM_CHAT_ID=-100123456789
```

The system works automatically once these variables are present.

## 🛣️ Traceroute Configuration

### Per-Host Traceroute Mode
The traceroute daemon supports **3 modes** configurable per-host:

| Mode | Protocol | Use Case |
|------|----------|----------|
| `icmp` | ICMP Echo | **Default.** Most compatible, works like ping. |
| `udp` | UDP | Classic traceroute. Works when ICMP is blocked. |
| `tcp` | TCP SYN | Best for hosts behind strict firewalls (uses `tcptraceroute`). |

**Usage in `config/Targets`:**
```ini
++MyServer
menu = My Server
title = My Server Description
host = 1.2.3.4
traceroute_mode = icmp

++FirewalledServer
menu = Firewalled Server
title = This host blocks ICMP and UDP
host = 5.6.7.8
traceroute_mode = tcp
```

> **Default:** If `traceroute_mode` is not specified, `icmp` is used.

### Route Change Detection
The system automatically monitors route paths and alerts via Telegram when your **upstream provider changes**.

**What triggers an alert:**
- Provider appears or disappears (e.g., `twelve99.net` → `cogent.net`)

**What does NOT trigger an alert:**
- Internal load balancing within the same provider
- Timeout variations (`*` hops)
- Different routers at the same ISP


## ⚙️ Configuration (Environment Variables)

You can customize everything directly in the compose file or `.env`:

| Variable | Description | Example |
|----------|-------------|---------|
| `TELEGRAM_BOT_TOKEN` | Bot Token from @BotFather | `12345...` |
| `TELEGRAM_CHAT_ID` | Chat/Channel ID | `-100...` |
| `SMOKEPING_LOGO_URL` | Logo URL (remote or local) | `https://example.com/logo.svg` |
| `SMOKEPING_COLOR_SIDEBAR_BG` | Sidebar background color | `#233350` |
| `SMOKEPING_BRAND_NAME` | Brand name in footer | `My Company` |
| `SMOKEPING_BRAND_URL` | Brand link | `https://example.com` |
| `TRACEPING_INTERVAL` | Traceroute frequency (seconds) | `300` |
| `SMOKEPING_TITLE` | Application Title | `Network Monitor` |
| `SMOKEPING_OWNER` | Owner Name | `NOC Team` |
| `PUID` / `PGID` | User/Group ID | `1000` |
| `TZ` | Timezone | `Europe/London` |

## 📦 Docker Hub

The image is available on Docker Hub:
- `sistemasminorisa/smokeping:latest` - Latest version
- `sistemasminorisa/smokeping:2.9.0` - Version 2.9.0

## 🔧 Troubleshooting

### "No such file or directory" for .rrd files
**Symptom:** You see errors like `ERROR: opening '/data/CDN/CloudFlare.rrd': No such file or directory`
**Cause:** This is **normal** on first run. RRD files are generated automatically.
**Solution:** Wait 5-10 minutes for the first cycle to complete.

### Logo not showing
1. Check `SMOKEPING_LOGO_URL` reaches a valid image.
2. If using local file, ensure volume mount is correct.

## 🤝 Contributing

Contributions are welcome. Please fork and submit a Pull Request.

## 🔗 Links

- [Docker Hub](https://hub.docker.com/r/sistemasminorisa/smokeping)
- [SmokePing Official](https://oss.oetiker.ch/smokeping/)
- [LinuxServer.io](https://www.linuxserver.io/)

---

**Developed with ❤️ by [everyWAN](https://everywan.com)**
