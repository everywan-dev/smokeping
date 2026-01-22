FROM linuxserver/smokeping:latest

# ==========================================
# 1. Install Dependencies
# ==========================================
# We need Perl DBI/DBD::SQLite for traceroute storage
# and standard system utilities
RUN apk add --no-cache \
    python3 \
    py3-pip \
    curl \
    imagemagick \
    ttf-dejavu \
    bind-tools \
    tcptraceroute \
    dos2unix \
    perl-dbi \
    perl-dbd-sqlite \
    perl-cgi

# Directory setup for persistent history
RUN mkdir -p /opt/traceroute_history /opt/smokeping/lib

# ==========================================
# 2. Add TracePing Backend Scripts
# ==========================================
COPY traceping_daemon.pl /opt/smokeping/traceping_daemon.pl
COPY traceping_server_simple.pl /opt/smokeping/traceping_server_simple.pl
COPY traceping.cgi /usr/share/webapps/smokeping/traceping.cgi
COPY traceping.cgi.pl /usr/share/webapps/smokeping/traceping.cgi.pl

# ==========================================
# 3. Add Custom Frontend Assets
# ==========================================
COPY frontend/ /usr/share/webapps/smokeping/
COPY frontend/basepage.html /etc/smokeping/basepage.html

# Copy default config (will be used by init script if config is empty)
COPY config/Targets /defaults/Targets
COPY config/Probes /defaults/Probes

# ==========================================
# 4. Setup Init Scripts (LSIO custom hooks)
# ==========================================
# LinuxServer.io supports /custom-cont-init.d for custom initialization
RUN mkdir -p /custom-cont-init.d

COPY scripts/init.d/99-custom-config.sh /custom-cont-init.d/99-custom-config.sh
COPY scripts/init.d/99-start-traceping-daemon.sh /custom-cont-init.d/99-start-traceping-daemon.sh
COPY scripts/init.d/99-start-traceping-server.sh /custom-cont-init.d/99-start-traceping-server.sh

# ==========================================
# 5. Permissions & Cleanup
# ==========================================
RUN dos2unix /custom-cont-init.d/99-custom-config.sh \
    /custom-cont-init.d/99-start-traceping-daemon.sh \
    /custom-cont-init.d/99-start-traceping-server.sh \
    /opt/smokeping/traceping_daemon.pl \
    /opt/smokeping/traceping_server_simple.pl \
    /usr/share/webapps/smokeping/traceping.cgi \
    /usr/share/webapps/smokeping/traceping.cgi.pl \
    /etc/smokeping/basepage.html && \
    chmod 755 /custom-cont-init.d/99-custom-config.sh \
    /custom-cont-init.d/99-start-traceping-daemon.sh \
    /custom-cont-init.d/99-start-traceping-server.sh \
    /opt/smokeping/traceping_daemon.pl \
    /opt/smokeping/traceping_server_simple.pl \
    /usr/share/webapps/smokeping/traceping.cgi \
    /usr/share/webapps/smokeping/traceping.cgi.pl

# ==========================================
# 6. Default Environment Variables
# ==========================================
ENV TRACEPING_INTERVAL=300 \
    TRACEPING_RETENTION_DAYS=365 \
    TRACEPING_PORT=9000 \
    SMOKEPING_HOSTNAME=smokeping-master
