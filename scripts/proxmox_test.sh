#!/bin/bash

# Cloudflare Tunnel Installation for Proxmox - TEST VERSION
# This is a simplified test version to debug issues

echo "🌐 Cloudflare Tunnel Installation Script Started"
echo "Arguments received: $@"
echo "Number of arguments: $#"
echo "Current user ID: $EUID"
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

# Check if token is provided
if [ -z "$1" ]; then
    echo "❌ ERROR: Missing Cloudflare tunnel token!"
    echo ""
    echo "Usage: $0 <cloudflare_tunnel_token>"
    echo ""
    echo "To get your token:"
    echo "1. Go to https://one.dash.cloudflare.com/"
    echo "2. Navigate to Zero Trust > Access > Tunnels"
    echo "3. Create a new tunnel or select existing one"
    echo "4. Copy the token from the installation command"
    exit 1
fi

TOKEN="$1"
echo "✅ Token received: ${TOKEN:0:20}..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ ERROR: This script must be run as root"
    echo "On Proxmox, you should already be root"
    echo "Current EUID: $EUID"
    exit 1
fi

echo "✅ Running as root (EUID: $EUID)"

# Test basic commands
echo "🔧 Testing basic commands..."

# Test apt update
echo "Testing apt update..."
if apt update > /dev/null 2>&1; then
    echo "✅ apt update works"
else
    echo "❌ apt update failed"
    exit 1
fi

# Test wget
echo "Testing wget..."
if command -v wget > /dev/null 2>&1; then
    echo "✅ wget is available"
else
    echo "📦 Installing wget..."
    apt install wget -y
fi

# Test curl
echo "Testing curl..."
if command -v curl > /dev/null 2>&1; then
    echo "✅ curl is available"
else
    echo "📦 Installing curl..."
    apt install curl -y
fi

# Test download cloudflared
echo "🌐 Testing Cloudflared download..."
TEMP_FILE="/tmp/cloudflared-test.deb"
if wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O "$TEMP_FILE"; then
    echo "✅ Cloudflared download successful"
    echo "File size: $(ls -lh $TEMP_FILE | awk '{print $5}')"
    rm -f "$TEMP_FILE"
else
    echo "❌ Cloudflared download failed"
    exit 1
fi

# Test systemctl
echo "Testing systemctl..."
if command -v systemctl > /dev/null 2>&1; then
    echo "✅ systemctl is available"
else
    echo "❌ systemctl not found - this might not be a systemd system"
fi

echo ""
echo "🎉 All tests passed! The system is ready for Cloudflare Tunnel installation."
echo ""
echo "To run the full installation, use:"
echo "curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/proxmox.sh | bash -s $TOKEN"
