#!/bin/sh

# ==============================================================================
# SmokePing Custom Configuration Script
# ==============================================================================
# Uses awk instead of sed to avoid issues with special characters in URLs

echo "[custom-init] Applying custom configuration..."

# Copiar configuración personalizada si existen
[ -f /defaults/Targets ] && cp -f /defaults/Targets /config/Targets
[ -f /defaults/Probes ] && cp -f /defaults/Probes /config/Probes
[ -f /defaults/Presentation ] && cp -f /defaults/Presentation /config/Presentation
[ -f /defaults/Alerts ] && cp -f /defaults/Alerts /config/Alerts

# Copiar basepage personalizado
if [ -f /usr/share/webapps/smokeping/basepage.html ]; then
    cp -f /usr/share/webapps/smokeping/basepage.html /etc/smokeping/basepage.html
elif [ -f /usr/share/smokeping/www/basepage.html ]; then
    cp -f /usr/share/smokeping/www/basepage.html /etc/smokeping/basepage.html
fi

# Configurar logo URL
LOGO_URL=${SMOKEPING_LOGO_URL:-'images/smokeping.png'}
if [ -f /etc/smokeping/basepage.html ]; then
    echo "[custom-init] Setting Logo URL: $LOGO_URL"
    export LOGO_URL
    perl -0777 -i -pe 's/\{\s*\{\s*SMOKEPING_LOGO_URL\s*\}\s*\}/$ENV{LOGO_URL}/g' /etc/smokeping/basepage.html
fi

# Configurar color del sidebar
SIDEBAR_BG=${SMOKEPING_COLOR_SIDEBAR_BG:-'#233350'}
if [ -f /etc/smokeping/basepage.html ]; then
    echo "[custom-init] Setting Sidebar Color: $SIDEBAR_BG"
    export SIDEBAR_BG
    # Replace placeholder if exists, otherwise append strict CSS override at the end of style block
    perl -0777 -i -pe 's/\{\s*\{\s*SMOKEPING_COLOR_SIDEBAR_BG\s*\}\s*\}/$ENV{SIDEBAR_BG}/g' /etc/smokeping/basepage.html
    
    # Force injection of dynamic styles
    perl -0777 -i -pe 's/<\/style>/#sidebarCollapse, #sidebarCollapse:hover, #sidebarCollapse:focus, #sidebar .custom-menu .btn.btn-primary, #sidebar .custom-menu .btn.btn-primary:hover, #sidebar .custom-menu .btn.btn-primary:focus { background: transparent !important; border-color: transparent !important; box-shadow: none !important; }\n#sidebar .custom-menu .btn.btn-primary:after, #sidebar .custom-menu .btn.btn-primary:hover:after, #sidebar .custom-menu .btn.btn-primary:focus:after { background: $ENV{SIDEBAR_BG} !important; }\n#filter, input[name="filter"] { border-color: $ENV{SIDEBAR_BG} !important; border-width: 2px !important; background: $ENV{SIDEBAR_BG} !important; color: #ffffff !important; }\n<\/style>/' /etc/smokeping/basepage.html
fi

# Configurar marca en footer (usando awk para evitar problemas con URLs)
BRAND_NAME=${SMOKEPING_BRAND_NAME:-''}
BRAND_URL=${SMOKEPING_BRAND_URL:-''}
if [ -n "$BRAND_NAME" ] && [ -n "$BRAND_URL" ]; then
    BRAND_FOOTER=" | <a href=\"$BRAND_URL\" target=\"_blank\">$BRAND_NAME</a>"
else
    BRAND_FOOTER=""
fi

if [ -f /etc/smokeping/basepage.html ]; then
    awk -v footer="$BRAND_FOOTER" '{gsub(/\{\{BRAND_FOOTER\}\}/, footer)}1' /etc/smokeping/basepage.html > /tmp/basepage.tmp && mv /tmp/basepage.tmp /etc/smokeping/basepage.html
fi

# Configurar General (owner, contact) usando awk
if [ -f /config/General ]; then
    OWNER="${SMOKEPING_OWNER:-SmokePing Admin}"
    CONTACT="${SMOKEPING_CONTACT:-admin@example.com}"
    
    awk -v owner="$OWNER" '/^owner/ {$0 = "owner    = " owner} 1' /config/General > /tmp/General.tmp && mv /tmp/General.tmp /config/General
    awk -v contact="$CONTACT" '/^contact/ {$0 = "contact  = " contact} 1' /config/General > /tmp/General.tmp && mv /tmp/General.tmp /config/General
fi

echo "[custom-init] Custom configuration applied."

# Configurar hostname para gráficos
SMOKEPING_HOSTNAME=${SMOKEPING_HOSTNAME:-smokeping-master}
echo "[custom-init] Hostname: $SMOKEPING_HOSTNAME"

if [ -f /config/General ]; then
    if grep -q '^display_name' /config/General; then
        awk -v hn="$SMOKEPING_HOSTNAME" '/^display_name/ {$0 = "display_name = " hn} 1' /config/General > /tmp/General.tmp && mv /tmp/General.tmp /config/General
    else
        echo "display_name = $SMOKEPING_HOSTNAME" >> /config/General
    fi
fi


# ==============================================================================
# Inject High-Priority Apache Configuration for Traceping Proxy
# ==============================================================================
# We create 00-traceping.conf in /config/site-confs/ so it loads BEFORE
# smokeping.conf (alphabetic order). This ensures our ProxyPass matches
# before the conflicting Alias /smokeping in smokeping.conf.

echo "[custom-init] Injecting Apache Proxy configuration..."
mkdir -p /config/site-confs
cat > /config/site-confs/00-traceping.conf << 'EOF'
# TracePing Proxy Configuration
# Loaded via IncludeOptional /config/site-confs/*.conf
# Loads FIRST to override Alias directives in smokeping.conf

LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so

<Location /smokeping/traceping.cgi>
    SetHandler None
    ProxyPass http://127.0.0.1:9000/smokeping/traceping.cgi
    ProxyPassReverse http://127.0.0.1:9000/smokeping/traceping.cgi
</Location>
EOF

echo "[custom-init] Configuration complete."
