#!/bin/bash

# Cloudflare Tunnel Installation for Proxmox
# This script installs cloudflared directly on Proxmox OS

# Enable debug mode
set -x  # Show commands being executed

echo "🌐 Cloudflare Tunnel Installation Script Started"
echo "Arguments received: $@"
echo "Number of arguments: $#"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to install Cloudflare Tunnel
install_cloudflare_tunnel() {
    local token="$1"
    
    echo "🌐 Starting Cloudflare Tunnel installation on Proxmox..."
    echo "Token received: ${token:0:20}..." # Show only first 20 chars for security
    
    # Validate token parameter
    if [ -z "$token" ]; then
        log_error "Cloudflare tunnel token is required!"
        echo ""
        echo "Usage: $0 <cloudflare_tunnel_token>"
        echo ""
        echo "To get your token:"
        echo "1. Go to https://one.dash.cloudflare.com/"
        echo "2. Navigate to Zero Trust > Access > Tunnels"
        echo "3. Create a new tunnel or select existing one"
        echo "4. Copy the token from the installation command"
        echo ""
        exit 1
    fi
    
    # 1. Update system and install dependencies
    log_step "Updating system packages..."
    apt update && apt upgrade -y
    apt install wget curl -y
    
    # 2. Download and install cloudflared
    log_step "Downloading and installing cloudflared..."
    
    # Download the latest cloudflared package
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    
    # Install the package
    dpkg -i cloudflared-linux-amd64.deb
    
    # Clean up downloaded package
    rm cloudflared-linux-amd64.deb
    
    log_info "Cloudflared installed successfully!"
    
    # 3. Install and configure the service
    log_step "Installing Cloudflare Tunnel service..."
    
    # Install the service with the provided token
    cloudflared service install "$token"
    
    log_info "Cloudflare Tunnel service installed and configured!"
    
    # 4. Enable and start the service
    log_step "Starting Cloudflare Tunnel service..."
    
    systemctl enable cloudflared
    systemctl start cloudflared
    
    # 5. Display service status
    log_step "Checking service status..."
    
    if systemctl is-active --quiet cloudflared; then
        log_info "✅ Cloudflare Tunnel service is running!"
    else
        log_warn "⚠️  Cloudflare Tunnel service may not be running properly"
    fi
    
    # 6. Display installation summary
    display_summary
}

# Function to display installation summary
display_summary() {
    echo ""
    log_info "🎉 Cloudflare Tunnel installation completed!"
    echo ""
    echo "📋 Summary:"
    echo "  ✅ System updated"
    echo "  ✅ Cloudflared installed"
    echo "  ✅ Tunnel service configured"
    echo "  ✅ Service enabled and started"
    echo ""
    echo "🔧 Service Management Commands:"
    echo "  systemctl status cloudflared    # Check service status"
    echo "  systemctl start cloudflared     # Start service"
    echo "  systemctl stop cloudflared      # Stop service"
    echo "  systemctl restart cloudflared   # Restart service"
    echo "  systemctl logs cloudflared      # View logs"
    echo ""
    echo "📊 Current Status:"
    systemctl status cloudflared --no-pager -l
    echo ""
    echo "🌐 Your Proxmox server is now accessible through Cloudflare Tunnel!"
    echo "   Configure your tunnel routes in the Cloudflare dashboard:"
    echo "   https://one.dash.cloudflare.com/"
}

# Function to show help
show_help() {
    echo "Cloudflare Tunnel Installation Script for Proxmox"
    echo ""
    echo "Usage:"
    echo "  $0 <cloudflare_tunnel_token>"
    echo ""
    echo "Parameters:"
    echo "  cloudflare_tunnel_token    Your Cloudflare tunnel token"
    echo ""
    echo "Examples:"
    echo "  $0 eyJhIjoiYWJjZGVmZ2hpams...your_token_here"
    echo ""
    echo "To get your token:"
    echo "1. Go to https://one.dash.cloudflare.com/"
    echo "2. Navigate to Zero Trust > Access > Tunnels"
    echo "3. Create a new tunnel or select existing one"
    echo "4. Copy the token from the installation command"
    echo ""
    echo "Remote installation:"
    echo "  curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/proxmox.sh | bash -s YOUR_TOKEN"
}

# Main execution
main() {
    echo "🔧 Main function called with arguments: $@"
    
    # Check if help is requested
    if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
        show_help
        exit 0
    fi
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        log_error "On Proxmox, you should already be root"
        log_error "On other systems, use: sudo $0 $*"
        exit 1
    fi
    
    # Check if token is provided
    if [ -z "$1" ]; then
        log_error "Missing Cloudflare tunnel token!"
        echo ""
        show_help
        exit 1
    fi
    
    # Install Cloudflare Tunnel
    install_cloudflare_tunnel "$1"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
