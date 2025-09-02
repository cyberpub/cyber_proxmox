#!/bin/bash

# Cloudflare Tunnel Installation for Proxmox - SIMPLE VERSION

echo "🌐 Cloudflare Tunnel Installation for Proxmox"
echo "=============================================="

# Get token from first argument
TOKEN="$1"

# Check if token is provided
if [ -z "$TOKEN" ]; then
    echo "❌ ERROR: Cloudflare tunnel token is required!"
    echo ""
    echo "Usage: $0 <cloudflare_tunnel_token>"
    echo ""
    echo "Example:"
    echo "  curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/proxmox_simple.sh | bash -s YOUR_TOKEN"
    exit 1
fi

echo "✅ Token received: ${TOKEN:0:20}..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ ERROR: This script must be run as root"
    echo "Current user: $(whoami) (EUID: $EUID)"
    exit 1
fi

echo "✅ Running as root"

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install dependencies
echo "📦 Installing dependencies..."
apt install wget curl -y

# Download cloudflared
echo "⬇️  Downloading Cloudflared..."
cd /tmp
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

# Install cloudflared
echo "📦 Installing Cloudflared..."
dpkg -i cloudflared-linux-amd64.deb

# Clean up
rm cloudflared-linux-amd64.deb

# Install service
echo "⚙️  Installing Cloudflare Tunnel service..."
cloudflared service install "$TOKEN"

# Enable and start service
echo "🚀 Starting Cloudflare Tunnel service..."
systemctl enable cloudflared
systemctl start cloudflared

# Check status
echo "📊 Checking service status..."
sleep 5
systemctl status cloudflared --no-pager

echo ""
echo "🎉 Cloudflare Tunnel installation completed!"
echo ""
echo "Service management commands:"
echo "  systemctl status cloudflared    # Check status"
echo "  systemctl start cloudflared     # Start service"
echo "  systemctl stop cloudflared      # Stop service"
echo "  systemctl restart cloudflared   # Restart service"
echo "  journalctl -u cloudflared -f    # View logs"
echo ""
echo "🌐 Configure your tunnel at: https://one.dash.cloudflare.com/"
