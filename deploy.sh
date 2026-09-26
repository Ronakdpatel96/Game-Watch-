#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Deploying Game Data monitoring infrastructure..."
cd "$SCRIPT_DIR"

if [ ! -f "monitor.cpp" ]; then
    echo "Error: monitor.cpp not found."
    exit 1
fi

if [ ! -f "backend.js" ]; then
    echo "Error: backend.js not found."
    exit 1
fi

if [ ! -d "frontend" ]; then
    echo "Error: frontend directory not found."
    exit 1
fi

if [ ! -d "certs" ]; then
    echo "Error: certs directory not found."
    exit 1
fi

sudo mkdir -p /opt/gamedata

echo "Configuring deployment directory..."
sudo chown gamedata:gamedata /opt/gamedata
sudo chmod 755 /opt/gamedata

g++ monitor.cpp -o monitor

echo "stopping gamedata-monitor..."
sudo systemctl stop gamedata-monitor

echo "Deploying C++ monitor..."
sudo cp monitor /opt/gamedata/

echo "Setting monitor ownership..."
sudo chown gamedata:gamedata /opt/gamedata/monitor
sudo chmod 755 /opt/gamedata/monitor

echo "Deploying Node.js web server..."
sudo cp backend.js /opt/gamedata/
sudo chown gamedata:gamedata /opt/gamedata/backend.js


echo "Depliying frontend..."
sudo cp -r frontend /opt/gamedata/
sudo chown -R gamedata:gamedata /opt/gamedata/frontend

echo "Deploying certificates..."
sudo mkdir -p /opt/gamedata/certs
sudo cp certs/gamedata.home.arpa.pem /opt/gamedata/certs/
sudo chown gamedata:gamedata /opt/gamedata/certs/gamedata.home.arpa.pem
sudo chmod 644 /opt/gamedata/certs/gamedata.home.arpa.pem

sudo cp certs/gamedata.home.arpa-key.pem /opt/gamedata/certs/
sudo chown gamedata:gamedata /opt/gamedata/certs/gamedata.home.arpa-key.pem
sudo chmod 600 /opt/gamedata/certs/gamedata.home.arpa-key.pem

echo "Verifying deployment..."

if [ ! -f "/opt/gamedata/monitor" ]; then
    echo "Error: monitor was not deployed."
    exit 1
fi

if [ ! -f "/opt/gamedata/backend.js" ]; then
    echo "Error: backend.js was not deployed."
    exit 1
fi

if [ ! -d "/opt/gamedata/frontend" ]; then
    echo "Error: frontend was not deployed."
    exit 1
fi

if [ ! -d "/opt/gamedata/certs" ]; then
    echo "Error: certificates were not deployed."
    exit 1
fi

echo "Deployment files verified."

echo "Reloading systemd configuration"
sudo systemctl daemon-reload

echo "Restarting monitoring services..."
sudo systemctl restart gamedata-monitor
sudo systemctl restart gamedata-web

echo "Verifying services..."

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

echo "Deployment completed successfully."
