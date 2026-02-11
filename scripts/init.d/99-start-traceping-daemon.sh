#!/bin/sh

# Script to start the traceroute daemon in background
# Runs after smokeping is ready

echo "Starting traceping daemon..."

# Wait for the database to be ready
sleep 5

# Start the daemon in background
/opt/smokeping/traceping_daemon.pl > /config/traceping_daemon.log 2>&1 &

echo "Traceping daemon started (PID: $!)"
