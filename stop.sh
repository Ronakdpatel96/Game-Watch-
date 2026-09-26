#!/bin/bash
set -e

echo "Stopping Game Data monitoring structure..."

sudo systemctl stop gamedata-monitor
sudo systemctl stop gamedata-web

echo "Monitoring infrastructure stopped."
