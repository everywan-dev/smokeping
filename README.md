# SmokePing Docker - Custom Frontend & Integrated Traceroute

[![Docker Pulls](https://img.shields.io/docker/pulls/sistemasminorisa/smokeping.svg)](https://hub.docker.com/r/sistemasminorisa/smokeping)
[![Docker Image](https://img.shields.io/badge/docker-image-blue.svg)](https://hub.docker.com/r/sistemasminorisa/smokeping)

**SmokePing** Docker image featuring a modern custom frontend, integrated traceroute functionality, and Docker Swarm support. Based on [linuxserver/smokeping](https://hub.docker.com/r/linuxserver/smokeping).

## 🎯 Features

- ✅ **SmokePing 2.9.0** - Latest stable version
- ✅ **Modern Frontend** - Responsive and customized interface
- ✅ **Integrated Traceroute** - Live traceroute panel via internal API
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

### 3️⃣ Docker Swarm + Traefik (Recommended)
Run behind a Traefik proxy with automatic SSL.
- File: `docker-compose.traefik.yml`

```bash
docker stack deploy -c docker-compose.traefik.yml smokeping
```

## ⚙️ Configuration (Environment Variables)

You can customize everything directly in the compose file or `.env`:

| Variable | Description | Example |
|----------|-------------|---------|
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
