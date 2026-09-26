#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Configuring application history..."
mkdir -p /opt/gamedata
chown gamedata:gamedata /opt/gamedata
chmod 755 /opt/gamedata

echo "Installing Game Data monitoring infrastructure..."


if [ "$EUID" -ne 0 ]; then
	echo "Please run this script with sudo"
	exit 1
fi

echo "Installing dependencies..."

apt update

apt install -y \
	g++ \
	nodejs \
	npm \
	tcpdump \
	iproute2 \
	procps \
	util-linux

echo "Installing Node.js dependencies..."
cp "$PROJECT_DIR/package.json" /opt/gamedata/
chown gamedata:gamedata /opt/gamedata/package.json
runuser -u gamedata -- npm install --prefix /opt/gamedata

echo "Creating service account..."
if id gamedata >/dev/null 2>&1; then
	echo "Service account 'gamedata' already exists."
else
	useradd --system --create-home --shell /usr/sbin/nologin gamedata
	echo "Created service account 'gamedata'."
fi

echo "configuring gamedata-monitoring service..."

cat > /etc/systemd/system/gamedata-monitor.service <<EOF
[Unit]
Description=Game Data C++ Monitor
After=network.target

[Service]
Type=simple
User=gamedata
ExecStart=/opt/gamedata/monitor
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Configuring gamedata-web service..."

cat > /etc/systemd/system/gamedata-web.service <<EOF
[Unit]
Description=Game Data Web Server
After=network.target

[Service]
Type=simple
User=gamedata
WorkingDirectory=/opt/gamedata
ExecStart=/usr/bin/node /opt/gamedata/backend.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd configuration..."

systemctl daemon-reload

echo "Enabling services..."

systemctl enable gamedata-monitor
systemctl enable gamedata-web

echo "Verifying systemd services..."

if systemctl is-enabled --quiet gamedata-monitor; then
	echo "gamedata-monitor: ENABLED"
else
	echo "gamedata-monitor: FAILED TO ENABLE"
	exit 1
fi

if systemctl is-enabled --quiet gamedata-web; then
	echo "gamedata-web: ENABLED"
else
	echo "gamedata-web"
	exit 1
fi

echo "Installation completed successfully."


