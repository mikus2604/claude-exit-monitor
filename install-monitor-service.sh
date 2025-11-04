#!/bin/bash

# Install Claude Monitor as a systemd service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/claude-monitor.service"
SYSTEMD_DIR="/etc/systemd/system"

echo "=========================================="
echo "Claude Monitor Service Installer"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check if service file exists
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Error: Service file not found: $SERVICE_FILE"
    exit 1
fi

echo "1. Creating log directory..."
mkdir -p "$SCRIPT_DIR/logs"
echo "   ✓ Done"

echo ""
echo "2. Updating service file paths..."
sed "s|/root/Hannah-ai-codex|$SCRIPT_DIR|g" "$SERVICE_FILE" > "$SYSTEMD_DIR/claude-monitor.service"
echo "   ✓ Service file configured for $SCRIPT_DIR"

echo ""
echo "3. Installing systemd service..."
echo "   ✓ Service file copied to $SYSTEMD_DIR/claude-monitor.service"

echo ""
echo "4. Reloading systemd daemon..."
systemctl daemon-reload
echo "   ✓ Done"

echo ""
echo "5. Enabling service (auto-start on boot)..."
systemctl enable claude-monitor.service
echo "   ✓ Service enabled"

echo ""
echo "6. Starting service..."
systemctl start claude-monitor.service
echo "   ✓ Service started"

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Service Commands:"
echo "  Status:   sudo systemctl status claude-monitor"
echo "  Stop:     sudo systemctl stop claude-monitor"
echo "  Start:    sudo systemctl start claude-monitor"
echo "  Restart:  sudo systemctl restart claude-monitor"
echo "  Logs:     sudo journalctl -u claude-monitor -f"
echo ""
echo "Monitor Logs:"
echo "  Daemon:    tail -f $SCRIPT_DIR/logs/daemon.log"
echo "  Alerts:    tail -f $SCRIPT_DIR/logs/daemon-alerts.log"
echo "  Resources: tail -f $SCRIPT_DIR/logs/daemon-resources.csv"
echo ""
echo "Quick Status:"
systemctl status claude-monitor --no-pager | head -20
echo ""
