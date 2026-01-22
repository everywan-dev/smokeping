#!/bin/bash

# Iniciar servidor Perl para traceping
echo "Starting TracePing server on port ${TRACEPING_PORT:-9000}..."
/opt/smokeping/traceping_server_simple.pl &
echo $! > /var/run/traceping_server.pid
echo "TracePing server started with PID $(cat /var/run/traceping_server.pid)"
