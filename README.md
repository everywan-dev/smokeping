# SmokePing Docker - Custom Frontend & Traceroute

[![Docker Pulls](https://img.shields.io/docker/pulls/sistemasminorisa/smokeping.svg)](https://hub.docker.com/r/sistemasminorisa/smokeping)
[![Docker Image](https://img.shields.io/badge/docker-image-blue.svg)](https://hub.docker.com/r/sistemasminorisa/smokeping)

Docker image de **SmokePing** con frontend personalizado y funcionalidad de traceroute integrada. Basado en [linuxserver/smokeping](https://hub.docker.com/r/linuxserver/smokeping) y [SmokePing](https://oss.oetiker.ch/smokeping/) por Tobi Oetiker.

## 🎯 Características

- ✅ **SmokePing 2.9.0** - Última versión estable
- ✅ **Frontend moderno** - Interfaz personalizada y responsive
- ✅ **Traceroute integrado** - Funcionalidad de traceroute con historial
- ✅ **Logo configurable** - Personaliza tu logo fácilmente
- ✅ **Hostname configurable** - Personaliza el nombre en los gráficos
- ✅ **Fácil instalación** - Un solo comando con docker-compose
- ✅ **Configuración mediante .env** - Variables de entorno simples

## 🚀 Instalación Rápida

### Prerrequisitos

- Docker
- Docker Compose

### Pasos

1. **Clonar el repositorio:**
```bash
git clone https://github.com/everywan-dev/smokeping.git
cd smokeping
```

2. **Configurar variables de entorno (Opcional):**
```bash
cp .env.example .env
# Edita .env con tus valores personalizados
nano .env
```

3. **Iniciar el servicio:**
```bash
docker-compose up -d
```

4. **Acceder a la interfaz:**
Abre tu navegador en: `http://localhost:8080/smokeping/`

¡Listo! 🎉

## ⚙️ Configuración Detallada

### Variables de Entorno

Todas las configuraciones se realizan mediante variables de entorno en el archivo `.env`. 

#### 1. Copiar el archivo de ejemplo

```bash
cp .env.example .env
```

#### 2. Editar el archivo .env

Abre `.env` con tu editor favorito y personaliza los valores:

```bash
nano .env
# o
vim .env
# o
code .env
```

### Variables Disponibles

#### Usuario y Grupo

```bash
PUID=1000    # ID del usuario (por defecto: 1000)
PGID=1000    # ID del grupo (por defecto: 1000)
```

**¿Cómo saber tu PUID y PGID?**
```bash
# En Linux/Mac
id

# Verás algo como: uid=1000(username) gid=1000(username)
# PUID sería 1000 y PGID sería 1000
```

#### Zona Horaria

```bash
TZ=Europe/Madrid
```

**Zonas horarias comunes:**
- `Europe/Madrid` - España
- `America/Mexico_City` - México
- `America/New_York` - Este de USA
- `America/Los_Angeles` - Oeste de USA
- `Asia/Tokyo` - Japón
- `UTC` - Tiempo Universal

[Lista completa de zonas horarias](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

#### Información de Contacto

```bash
SMOKEPING_OWNER=Mi Empresa          # Nombre que aparece en el footer
SMOKEPING_CONTACT=noc@miempresa.com # Email de contacto
SMOKEPING_TITLE=Monitoreo de Red    # Título de la aplicación
```

**Ejemplo:**
```bash
SMOKEPING_OWNER=Acme Corporation
SMOKEPING_CONTACT=noc@acme.com
SMOKEPING_TITLE=Acme Network Monitoring
```

#### Personalizar Logo

##### Paso 1: Preparar tu logo

Tu logo debe estar en formato **SVG, PNG o JPG**. Recomendamos SVG para mejor calidad.

**Tamaño recomendado:** El logo se ajusta automáticamente a 140x140px, pero recomendamos:
- **SVG**: Cualquier tamaño (se escala automáticamente)
- **PNG/JPG**: Mínimo 280x280px para buena calidad

##### Paso 2: Colocar el logo en el proyecto

Coloca tu logo en la carpeta `frontend/images/`:

```bash
# Ejemplo: copiar tu logo
cp /ruta/a/tu/logo.svg frontend/images/mi-logo.svg
```

##### Paso 3: Configurar en .env

Edita `.env` y cambia `SMOKEPING_LOGO_URL`:

```bash
SMOKEPING_LOGO_URL=images/mi-logo.svg
```

**Nota importante:** La ruta es relativa a `/usr/share/webapps/smokeping/` dentro del contenedor. Si colocas el logo en `frontend/images/`, la ruta será `images/nombre-del-archivo`.

##### Paso 4: Reiniciar el contenedor

```bash
docker-compose restart
```

**Ejemplo completo:**
```bash
# 1. Copiar logo
cp ~/Downloads/logo-empresa.svg frontend/images/logo-empresa.svg

# 2. Editar .env
SMOKEPING_LOGO_URL=images/logo-empresa.svg

# 3. Reiniciar
docker-compose restart
```

#### Personalizar Hostname en Gráficos

El hostname es el nombre que aparece en los títulos de los gráficos, por ejemplo:
- `Last 3 Hours from monitor-principal`
- `Last 30 Hours from monitor-principal`

**Configurar en .env:**
```bash
SMOKEPING_HOSTNAME=monitor-principal
```

**Ejemplos:**
```bash
SMOKEPING_HOSTNAME=datacenter-madrid
SMOKEPING_HOSTNAME=monitor-empresa
SMOKEPING_HOSTNAME=smokeping-prod
```

**Reiniciar después de cambiar:**
```bash
docker-compose restart
```

#### Branding en Footer (Opcional)

Si quieres añadir un enlace a tu marca en el footer:

```bash
SMOKEPING_BRAND_NAME=Mi Empresa
SMOKEPING_BRAND_URL=https://www.miempresa.com
```

Si dejas estos valores vacíos, no se mostrará nada en el footer.

#### Configuración de Traceroute

```bash
TRACEPING_INTERVAL=300              # Intervalo en segundos (por defecto: 300 = 5 minutos)
TRACEPING_RETENTION_DAYS=365        # Días de retención (por defecto: 365 = 1 año)
```

**Ejemplos:**
- `TRACEPING_INTERVAL=600` - Ejecutar traceroute cada 10 minutos
- `TRACEPING_RETENTION_DAYS=180` - Guardar historial por 6 meses

#### Puerto de Acceso

Por defecto, el servicio está disponible en el puerto **8080**. Para cambiarlo:

**Opción 1: En .env (recomendado)**
```bash
PORT=9090
```

**Opción 2: En docker-compose.yml**
Edita la línea:
```yaml
ports:
  - "9090:80"  # Cambia 9090 por el puerto que quieras
```

Luego reinicia:
```bash
docker-compose down
docker-compose up -d
```

### Ejemplo Completo de .env

```bash
# Usuario y Grupo
PUID=1000
PGID=1000

# Zona Horaria
TZ=America/Mexico_City

# Información de Contacto
SMOKEPING_OWNER=Acme Corporation
SMOKEPING_CONTACT=noc@acme.com
SMOKEPING_TITLE=Acme Network Monitoring

# Logo Personalizado
SMOKEPING_LOGO_URL=images/logo-acme.svg

# Hostname
SMOKEPING_HOSTNAME=monitor-acme

# Branding
SMOKEPING_BRAND_NAME=Acme Corp
SMOKEPING_BRAND_URL=https://www.acme.com

# Traceroute
TRACEPING_INTERVAL=300
TRACEPING_RETENTION_DAYS=365

# Puerto
PORT=8080
```

## 🎨 Personalización Avanzada

### Configurar Targets (Destinos a Monitorear)

1. Edita el archivo `config/Targets`:
```bash
nano config/Targets
```

2. Añade tus targets siguiendo la sintaxis de SmokePing:
```
++MiTarget
menu = Mi Target
title = Descripción del Target
host = ejemplo.com
```

3. Reinicia el contenedor:
```bash
docker-compose restart
```

**Documentación de SmokePing:** [Configuración de Targets](https://oss.oetiker.ch/smokeping/doc/index.en.html)

## 📦 Versiones Disponibles

La imagen está disponible en Docker Hub con los siguientes tags:

- `sistemasminorisa/smokeping:latest` - Última versión
- `sistemasminorisa/smokeping:2.9.0` - Versión específica 2.9.0

Para usar una versión específica, edita `docker-compose.yml`:

```yaml
image: sistemasminorisa/smokeping:2.9.0
```

## 🔧 Comandos Útiles

### Ver logs
```bash
docker-compose logs -f
```

### Reiniciar el servicio
```bash
docker-compose restart
```

### Detener el servicio
```bash
docker-compose down
```

### Actualizar la imagen
```bash
docker-compose pull
docker-compose up -d
```

### Ver el estado del contenedor
```bash
docker-compose ps
```

### Acceder al shell del contenedor
```bash
docker-compose exec smokeping sh
```

## 📁 Estructura del Proyecto

```
smokeping/
├── docker-compose.yml    # Configuración de Docker Compose
├── .env.example         # Ejemplo de variables de entorno
├── .env                 # Tus variables personalizadas (no se sube a git)
├── README.md            # Este archivo
├── LICENSE              # Licencia GPL v3
├── config/              # Configuración de SmokePing
│   ├── Targets          # Targets a monitorear
│   ├── Probes           # Configuración de probes
│   └── ...
├── frontend/            # Frontend personalizado
│   ├── basepage.html    # Template HTML principal
│   ├── css/             # Estilos CSS
│   ├── js/              # JavaScript
│   └── images/          # Imágenes y logos
└── scripts/             # Scripts de inicialización
```

## 🛠️ Solución de Problemas

### El logo no se muestra

1. Verifica que el archivo existe en `frontend/images/`
2. Verifica la ruta en `.env` (debe ser `images/nombre-archivo`)
3. Verifica los permisos del archivo
4. Reinicia el contenedor: `docker-compose restart`
5. Limpia la caché del navegador (Ctrl+F5)

### El hostname no cambia en los gráficos

1. Verifica que `SMOKEPING_HOSTNAME` está en `.env`
2. Reinicia el contenedor: `docker-compose restart`
3. Espera unos minutos para que se generen nuevos gráficos

### No puedo acceder al servicio

1. Verifica que el puerto está correcto: `docker-compose ps`
2. Verifica que no hay otro servicio usando el puerto
3. Verifica los logs: `docker-compose logs`

## 📝 Licencia

Este proyecto está basado en:

- **[SmokePing](https://oss.oetiker.ch/smokeping/)** - Copyright (C) 1999-2024 by Tobi Oetiker y contribuidores. Licencia GPL v3.
- **[linuxserver/smokeping](https://hub.docker.com/r/linuxserver/smokeping)** - Imagen base de Docker mantenida por LinuxServer.io.

### Modificaciones de everyWAN

Este proyecto incluye las siguientes mejoras y personalizaciones desarrolladas por **everyWAN**:

- **Frontend personalizado**: Interfaz de usuario moderna y responsive con diseño custom
- **Integración de Traceroute**: Funcionalidad completa de traceroute con historial almacenado en SQLite
- **Sistema de branding configurable**: Logo y textos personalizables mediante variables de entorno
- **Optimizaciones de Docker**: Imagen optimizada con todas las dependencias necesarias
- **Scripts de inicialización**: Automatización de configuración y despliegue

Estas modificaciones se proporcionan bajo la misma licencia GPL v3 que el proyecto original.

## 🙏 Agradecimientos

Queremos agradecer a:

- **Tobi Oetiker** y todos los contribuidores de [SmokePing](https://oss.oetiker.ch/smokeping/) por crear esta excelente herramienta de monitoreo de red
- **LinuxServer.io** por mantener la imagen base de Docker [linuxserver/smokeping](https://hub.docker.com/r/linuxserver/smokeping)
- La comunidad open source por su continuo apoyo y contribuciones

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📧 Soporte

- **Issues**: [GitHub Issues](https://github.com/everywan-dev/smokeping/issues)
- **Email**: Para soporte, contacta a través de los issues de GitHub

## 🔗 Enlaces

- [Docker Hub](https://hub.docker.com/r/sistemasminorisa/smokeping)
- [SmokePing Official](https://oss.oetiker.ch/smokeping/)
- [LinuxServer.io](https://www.linuxserver.io/)

---

**Desarrollado con ❤️ por [everyWAN](https://everywan.com)**
