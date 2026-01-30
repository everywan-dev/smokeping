FROM linuxserver/smokeping:latest

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
    perl-cgi \
    apache2-proxy \
    bash

RUN mkdir -p /opt/traceroute_history /opt/smokeping/lib

COPY traceroute_history/ /opt/traceroute_history/
COPY traceping_daemon.pl /opt/smokeping/traceping_daemon.pl
COPY traceping_server_simple.pl /opt/smokeping/traceping_server_simple.pl
COPY traceping.cgi /usr/share/webapps/smokeping/traceping.cgi
COPY traceping.cgi.pl /usr/share/webapps/smokeping/traceping.cgi.pl
COPY frontend/ /usr/share/webapps/smokeping/
COPY frontend/basepage.html /etc/smokeping/basepage.html
COPY config/Targets /defaults/Targets
COPY config/Probes /defaults/Probes
COPY config/Presentation /defaults/Presentation
COPY scripts/traceping-service-run /etc/services.d/traceping/run
COPY scripts/traceping-server-run /etc/services.d/traceping-server/run
COPY scripts/init.d/99-custom-config.sh /custom-cont-init.d/99-custom-config.sh

# Create symlinks for production-compatible paths
RUN ln -sf /usr/share/webapps/smokeping/js/scriptaculous /usr/share/webapps/smokeping/scriptaculous && \
    ln -sf /usr/share/webapps/smokeping/js/cropper /usr/share/webapps/smokeping/cropper && \
    ln -sf /usr/share/webapps/smokeping/js/smokeping.js /usr/share/webapps/smokeping/smokeping-zoom.js

# Configure Apache Proxy for traceping
# We continue to create the config file here, but the Include
# is injected at runtime by traceping-service-run into site-confs/smokeping.conf
RUN echo "Configuring Apache Proxy for traceping..." && \
    echo 'LoadModule proxy_module modules/mod_proxy.so' > /etc/apache2/conf.d/proxy_load.conf && \
    echo 'LoadModule proxy_http_module modules/mod_proxy_http.so' >> /etc/apache2/conf.d/proxy_load.conf && \
    echo '<Location /smokeping/traceping.cgi>' > /etc/apache2/conf.d/traceping.conf && \
    echo '    SetHandler None' >> /etc/apache2/conf.d/traceping.conf && \
    echo '    ProxyPass http://127.0.0.1:9000/smokeping/traceping.cgi' >> /etc/apache2/conf.d/traceping.conf && \
    echo '    ProxyPassReverse http://127.0.0.1:9000/smokeping/traceping.cgi' >> /etc/apache2/conf.d/traceping.conf && \
    echo '</Location>' >> /etc/apache2/conf.d/traceping.conf

# Final permissions and cleanup
# IMPORTANT: Remove traceping.cgi wrapper so mod_fcgid does not intercept requests
RUN rm /usr/share/webapps/smokeping/traceping.cgi && \
    dos2unix /etc/services.d/traceping/run \
    /etc/services.d/traceping-server/run \
    /custom-cont-init.d/99-custom-config.sh \
    /opt/smokeping/traceping_daemon.pl \
    /opt/smokeping/traceping_server_simple.pl \
    /usr/share/webapps/smokeping/traceping.cgi.pl \
    /etc/smokeping/basepage.html && \
    chmod +x /etc/services.d/traceping/run \
    /etc/services.d/traceping-server/run \
    /custom-cont-init.d/99-custom-config.sh \
    /opt/smokeping/traceping_daemon.pl \
    /opt/smokeping/traceping_server_simple.pl \
    /usr/share/webapps/smokeping/traceping.cgi.pl && \
    chmod +x /opt/traceroute_history/*.sh 2>/dev/null || true

ENV TRACEPING_INTERVAL=300 \
    TRACEPING_RETENTION_DAYS=365 \
    TRACEPING_PORT=9000 \
    SMOKEPING_BRAND_NAME="SmokePing" \
    SMOKEPING_BRAND_URL="" \
    SMOKEPING_LOGO_URL="images/smokeping.png"
