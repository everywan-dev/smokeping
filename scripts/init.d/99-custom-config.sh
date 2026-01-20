#!/bin/sh

# Copiar configuración personalizada
cp -f /defaults/Targets /config/Targets
cp -f /defaults/Probes /config/Probes

# Copiar basepage personalizado (prioridad: frontend personalizado > default)
if [ -f /usr/share/webapps/smokeping/basepage.html ]; then
    cp -f /usr/share/webapps/smokeping/basepage.html /etc/smokeping/basepage.html
elif [ -f /usr/share/smokeping/www/basepage.html ]; then
    cp -f /usr/share/smokeping/www/basepage.html /etc/smokeping/basepage.html
fi

LOGO_URL=${SMOKEPING_LOGO_URL:-'images/logo.svg'}
sed -i "s|{{SMOKEPING_LOGO_URL}}|$LOGO_URL|g" /etc/smokeping/basepage.html

# Configurar marca en footer (configurable)
BRAND_NAME=${SMOKEPING_BRAND_NAME:-''}
BRAND_URL=${SMOKEPING_BRAND_URL:-''}
if [ -n "$BRAND_NAME" ] && [ -n "$BRAND_URL" ]; then
    BRAND_FOOTER=" | <a href=\"$BRAND_URL\" target=\"_blank\">$BRAND_NAME</a>"
else
    BRAND_FOOTER=""
fi
sed -i "s|{{BRAND_FOOTER}}|$BRAND_FOOTER|g" /etc/smokeping/basepage.html

# Configurar General
if [ -f /config/General ]; then
    sed -i "s|^owner.*|owner    = ${SMOKEPING_OWNER}|g" /config/General
    sed -i "s|^contact.*|contact  = ${SMOKEPING_CONTACT}|g" /config/General
fi



echo "Custom configuration applied."

# Configurar hostname para gráficos
SMOKEPING_HOSTNAME=${SMOKEPING_HOSTNAME:-smokeping-master}
if [ -f /config/General ]; then
    # El hostname se usa en los títulos de los gráficos
    # Se puede configurar en General si es necesario
    echo "Hostname configurado: $SMOKEPING_HOSTNAME"
fi

# Configurar display_name (hostname para gráficos)
SMOKEPING_HOSTNAME=${SMOKEPING_HOSTNAME:-smokeping-master}
if [ -f /config/General ]; then
    if grep -q '^display_name' /config/General; then
        sed -i "s|^display_name.*|display_name = $SMOKEPING_HOSTNAME|g" /config/General
    else
        echo "display_name = $SMOKEPING_HOSTNAME" >> /config/General
    fi
fi
