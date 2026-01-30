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

## 🚀 Deployment Options

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

## 🔔 Telegram Alerts

Smokeping can now send alerts directly to Telegram when:
1.  Packet Loss is detected.
2.  Latency spikes occur.
3.  **Route Changes**: If the traceroute path changes, you get a notification with the old and new route.

### Configuration
Simply add these environment variables to your compose file:

```yaml
    environment:
      - TELEGRAM_BOT_TOKEN=123456789:AbCdeWgHiJkLmNoPqRsTuVwXyZ
      - TELEGRAM_CHAT_ID=-100123456789
```

The system works automatically once these variables are present.

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
