# SmokePing Docker - Enterprise Edition

This is a heavily enhanced Docker implementation of **SmokePing**, featuring a modern UI, integrated Traceroute, and full customization capabilities (Branding, Colors, Fonts) via environment variables.



## 🚀 Features

-   **Modern UI**: Updated aesthetics using Google Fonts and a clean design.
-   **Integrated Traceroute**: View valid traceroutes directly on the target's graph page.
    -   Backend daemon collects traceroutes efficiently for all targets.
    -   Frontend integration displays route data and history.
-   **Full Customization**: Change colors, fonts, logo, and footer text only using `docker-compose.yml` variables.
-   **Production Ready**: Includes Nginx proxy with correct redirection handling.
-   **Automated Init**: Custom scripts automatically apply your branding and settings on container startup.

---

## 🛠️ Quick Start

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/everywan-dev/smokeping.git
    cd smokeping
    ```

2.  **Configure environment**:
    Copy the example entry file and customize it:
    ```bash
    cp .env.example .env
    nano .env
    ```

3.  **Start the container**:
    ```bash
    docker-compose up -d
    ```

4.  **Access**:
    Open `http://localhost:8085` (or your configured port).

---

## 🎨 Customization (Theming & Branding)

You can fully customize the look and feel without touching any code. All settings are controlled via environment variables.

### Colors & Fonts
Define your corporate identity in `.env`:

```ini
# Colors (Hex, RGB, HSL)
SMOKEPING_COLOR_PRIMARY=#00cc00
SMOKEPING_COLOR_SECONDARY=#111111
SMOKEPING_COLOR_ACCENT=#33ff33
SMOKEPING_COLOR_SIDEBAR_BG=#000000
SMOKEPING_COLOR_SIDEBAR_TEXT=#00cc00
SMOKEPING_COLOR_HEADER_BG=#0a0a0a

# Typography
SMOKEPING_FONT_FAMILY=Poppins, sans-serif
SMOKEPING_FONT_URL=https://fonts.googleapis.com/css?family=Poppins:300,400,500,600,700
```

### Branding
Customize the footer and header information:

```ini
# Identity
SMOKEPING_OWNER=Neo
SMOKEPING_CONTACT=admin@example.com
SMOKEPING_HOSTNAME=monitor-node-1
SMOKEPING_TITLE=My Network Monitor

# Footer Link
SMOKEPING_BRAND_NAME=My Company
SMOKEPING_BRAND_URL=https://mycompany.com

# Custom Logo (Place your file in frontend/images/)
SMOKEPING_LOGO_URL=images/logo.svg
```

---

## 📡 Traceroute Configuration

The system automatically runs traceroutes for all defined targets in your config.

-   **Interval**: How often to run traceroute (default: 300s).
-   **Retention**: How long to keep history (default: 365 days).

Configuration in `.env`:
```ini
TRACEPING_INTERVAL=300
TRACEPING_RETENTION_DAYS=365
```

---

## ⚙️ Advanced Configuration

### Adding Targets
Edit `config/Targets` to add your hosts. The syntax follows standard SmokePing configuration.

Example:
```perl
++ MyTarget
menu = My Target Host
title = My Target Host
host = my.host.com
```

### Docker Image
The official image is available at DockerHub:
`sistemasminorisa/smokeping:latest`

---

## 🌐 Domain & SSL (Traefik)

This deployment uses **Traefik** as a reverse proxy to strictly manage routing and provide **Automatic HTTPS** (Let's Encrypt).

### Configuration
1.  Set your domain and email in `.env`:
    ```ini
    DOMAIN=smokeping.mycompany.com
    ACME_EMAIL=admin@mycompany.com
    ```
2.  Traefik will handle:
    -   Redirecting HTTP -> HTTPS.
    -   Getting/Renewing SSL certificates.
    -   Routing `/smokeping` to the web interface.
    -   Routing `/smokeping/traceping.cgi` to the backend service.

### Ports
-   **80**: HTTP (Auto-redirect to HTTPS).
-   **443**: HTTPS (Secure Access).
-   **Note**: Traefik manages these ports. The SmokePing container is not exposed directly.

## 🐝 Swarm / External Traefik Deployment

If you already have a Traefik instance running (e.g., in a Docker Swarm cluster or central proxy), use the provided `docker-compose.swarm.yml`.

1.  Ensure your external network is named `traefik-public` (or edit the yaml).
2.  Deploy using the swarm file:
    ```bash
    docker stack deploy -c docker-compose.swarm.yml smokeping
    # OR for plain docker-compose with external traefik:
    docker-compose -f docker-compose.swarm.yml up -d
    ```
3.  Ensure your `.env` file defines `DOMAIN` correctly.

---

## 📦 Build & Release

To build and push the images manually:

```bash
# Build
docker build -t sistemasminorisa/smokeping:latest .
docker tag sistemasminorisa/smokeping:latest sistemasminorisa/smokeping:2.9.0

# Push
docker push sistemasminorisa/smokeping:latest
docker push sistemasminorisa/smokeping:2.9.0
```

## 🔧 Troubleshooting & Permissions

If graphs are not appearing or data is not persisting, it is likely a **Permissions Issue**.

The container runs as user **1000:1000** by default. Ensure your host directories have the correct ownership:

```bash
# Correct permissions for mapped volumes
chown -R 1000:1000 ./data
chown -R 1000:1000 ./config
chown -R 1000:1000 ./logs
```

If you need to run as a different user (e.g. root or a specific service account), modify `PUID` and `PGID` in `.env`:

```ini
PUID=1001
PGID=1001
```

---

## 📜 License
MIT License. See `LICENSE` file for details.
