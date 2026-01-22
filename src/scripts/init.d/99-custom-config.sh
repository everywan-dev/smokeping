#!/bin/sh
# ==============================================================================
# SmokePing Custom Configuration Script
# ==============================================================================

echo "[custom-init] Starting custom configuration..."

# --- 1. Copy Configuration Files (Safe Run-Once) ---
echo "[custom-init] Checking configuration status..."

CONFIG_MARKER="/config/.enterprise_installed"

if [ ! -f "$CONFIG_MARKER" ]; then
    echo "[custom-init] First run detected (or factory reset). Installing Enterprise Configuration..."
    
    # Force overwrite of critical config files from our defaults
    # This replaces the generic LSIO defaults that might have just been created
    if [ -d /defaults ]; then
        for file in /defaults/*; do
            filename=$(basename "$file")
            echo "[custom-init] Initializing $filename..."
            cp -rf "$file" "/config/$filename"
        done
    fi
    
    # Create marker file to prevent future overwrites
    touch "$CONFIG_MARKER"
    echo "[custom-init] Enterprise configuration installed. User changes will now be respected."
else
    echo "[custom-init] System already initialized ($CONFIG_MARKER exists). Skipping config overwrite."
fi

# Force update of basepage.html (system template) which is handled below...

# --- 2. Setup Basepage ---
echo "[custom-init] Setting up basepage..."
# Always copy fresh basepage from source to ensure clean slate for sed
if [ -f /usr/share/webapps/smokeping/basepage.html ]; then
    cp -f /usr/share/webapps/smokeping/basepage.html /etc/smokeping/basepage.html
fi

# Apply Logo
LOGO_URL=${SMOKEPING_LOGO_URL:-'images/logo.svg'}
sed -i "s#{{SMOKEPING_LOGO_URL}}#$LOGO_URL#g" /etc/smokeping/basepage.html

# Apply Owner Name
OWNER_NAME=${SMOKEPING_OWNER:-'SmokePing Admin'}
sed -i "s#{{SMOKEPING_OWNER_NAME}}#$OWNER_NAME#g" /etc/smokeping/basepage.html

# Apply Branding Footer
BRAND_NAME=${SMOKEPING_BRAND_NAME:-''}
BRAND_URL=${SMOKEPING_BRAND_URL:-''}
if [ -n "$BRAND_NAME" ] && [ -n "$BRAND_URL" ]; then
    BRAND_FOOTER=" | <a href=\"$BRAND_URL\" target=\"_blank\">$BRAND_NAME</a>"
else
    BRAND_FOOTER=""
fi
sed -i "s@{{BRAND_FOOTER}}@$BRAND_FOOTER@g" /etc/smokeping/basepage.html

# Apply Font URL
FONT_URL=${SMOKEPING_FONT_URL:-'https://fonts.googleapis.com/css?family=Poppins:300,400,500,600,700,800,900'}
sed -i "s#{{SMOKEPING_FONT_URL}}#$FONT_URL#g" /etc/smokeping/basepage.html

# --- 3. Global Settings in Config ---
echo "[custom-init] Applying global settings..."
if [ -f /config/General ]; then
    sed -i "s|^owner.*|owner    = ${SMOKEPING_OWNER}|g" /config/General
    sed -i "s|^contact.*|contact  = ${SMOKEPING_CONTACT}|g" /config/General
    
    SMOKEPING_HOSTNAME=${SMOKEPING_HOSTNAME:-smokeping-master}
    if grep -q '^display_name' /config/General; then
        sed -i "s|^display_name.*|display_name = $SMOKEPING_HOSTNAME|g" /config/General
    else
        echo "display_name = $SMOKEPING_HOSTNAME" >> /config/General
    fi
fi

# --- 4. Generate Dynamic CSS ---
echo "[custom-init] Generating dynamic CSS..."

COLOR_PRIMARY=${SMOKEPING_COLOR_PRIMARY:-#007bff}
COLOR_SECONDARY=${SMOKEPING_COLOR_SECONDARY:-#6c757d}
COLOR_ACCENT=${SMOKEPING_COLOR_ACCENT:-#00d4ff}
COLOR_SIDEBAR_BG=${SMOKEPING_COLOR_SIDEBAR_BG:-#1a1a2e}
COLOR_SIDEBAR_TEXT=${SMOKEPING_COLOR_SIDEBAR_TEXT:-rgba(255,255,255,0.8)}
COLOR_HEADER_BG=${SMOKEPING_COLOR_HEADER_BG:-#16213e}
FONT_FAMILY=${SMOKEPING_FONT_FAMILY:-'Poppins, sans-serif'}

cat > /usr/share/webapps/smokeping/css/custom-colors.css << EOF
/* Custom Theme - Generated at Startup */
:root {
    --sp-primary: ${COLOR_PRIMARY};
    --sp-secondary: ${COLOR_SECONDARY};
    --sp-accent: ${COLOR_ACCENT};
    --sp-sidebar-bg: ${COLOR_SIDEBAR_BG};
    --sp-sidebar-text: ${COLOR_SIDEBAR_TEXT};
    --sp-header-bg: ${COLOR_HEADER_BG};
    --sp-font-family: ${FONT_FAMILY};
}

body {
    font-family: var(--sp-font-family) !important;
}

/* Sidebar */
#sidebar {
    background: var(--sp-sidebar-bg) !important;
}

#sidebar .list-unstyled li a {
    color: var(--sp-sidebar-text) !important;
}

#sidebar .list-unstyled li.active > a,
#sidebar .list-unstyled li a:hover {
    color: var(--sp-accent) !important;
}

/* Header/Logo Area */
#sidebar .logo {
    background: var(--sp-header-bg) !important;
}

/* Sidebar Toggle Button - Invisible Style */
#sidebarCollapse {
    background-color: transparent !important;
    border: none !important;
    color: var(--sp-sidebar-text) !important;
    box-shadow: none !important;
}

#sidebarCollapse:hover, 
#sidebarCollapse:focus, 
#sidebarCollapse:active {
    background-color: transparent !important;
    border: none !important;
    color: var(--sp-accent) !important;
    box-shadow: none !important;
    outline: none !important;
}

/* Buttons */
.btn-primary, a.btn-primary {
    background-color: var(--sp-primary) !important;
    border-color: var(--sp-primary) !important;
}

.btn-primary:hover {
    background-color: var(--sp-accent) !important;
    border-color: var(--sp-accent) !important;
}

/* Links */
a { color: var(--sp-primary); }
a:hover { color: var(--sp-accent); }

/* Traceroute Panel Styling override */
.traceroute-panel h4 span {
    background: var(--sp-primary) !important;
}
EOF

# Ensure CSS reference exists in basepage
if ! grep -q "custom-colors.css" /etc/smokeping/basepage.html; then
    sed -i 's|</head>|<link rel="stylesheet" href="/smokeping/css/custom-colors.css">\n</head>|' /etc/smokeping/basepage.html
fi

# --- 5. Fix Permissions ---
echo "[custom-init] Fixing permissions..."
PUID=${PUID:-1000}
PGID=${PGID:-1000}
chown -R $PUID:$PGID /config /data /usr/share/webapps/smokeping
# Ensure cache dir exists and is writable
mkdir -p /var/cache/smokeping
chown -R $PUID:$PGID /var/cache/smokeping

echo "[custom-init] Configuration complete."
