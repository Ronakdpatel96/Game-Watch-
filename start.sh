#!/bin/bash
set -e

echo "Starting Game Data monitoring infrastructure..."

sudo systemctl start gamedata-monitor
sudo systemctl start gamedata-web

echo "checking services..."

if systemctl is-active --quiet gamedata-monitor; then
	echo "gamedata-monitor: RUNNING"
else
	echo "gamedata-monitor: FAILED"
	exit 1
fi

if systemctl is-active --quiet gamedata-web; then
	echo "gamedata-web: RUNNING"
else
	echo "gamedata-web: FAILED"
	exit 1
fi

echo "Monitoring infrastructure started successfully."
