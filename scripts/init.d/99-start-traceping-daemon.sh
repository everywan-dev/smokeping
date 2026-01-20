#!/bin/sh

# Script para iniciar el daemon de traceroute en background
# Se ejecuta después de que smokeping esté listo

echo "Starting traceping daemon..."

# Esperar a que la base de datos esté lista
sleep 5

# Iniciar el daemon en background
/opt/smokeping/traceping_daemon.pl > /config/traceping_daemon.log 2>&1 &

echo "Traceping daemon started (PID: $!)"
