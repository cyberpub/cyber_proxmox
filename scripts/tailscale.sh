#!/bin/bash

# Cyber Proxmox Tailscale VM Installation Script (Modular Version)
# Compatible with Ubuntu 24.04 Server
# Uses modular functions for better maintainability

set -e  # Exit on any error

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="$(dirname "$SCRIPT_DIR")/functions"

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

# Source function modules
source_functions() {
    local functions=(
        "configure_timezone.sh"
        "generate_ssh_key.sh"
        "extend_lvm.sh"
        "install_tools.sh"
        "configure_aliases.sh"
    )
    
    # Create temporary functions directory
    mkdir -p /tmp/cyber_proxmox_functions
    
    for func in "${functions[@]}"; do
        local func_path="/tmp/cyber_proxmox_functions/$func"
        
        # Download function if not already present locally
        if [ ! -f "$FUNCTIONS_DIR/$func" ] && [ ! -f "$func_path" ]; then
            log_info "Downloading function: $func"
            if curl -fsSL "https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/functions/$func" -o "$func_path"; then
                source "$func_path"
            else
                log_warn "Failed to download function: $func"
            fi
        elif [ -f "$FUNCTIONS_DIR/$func" ]; then
            # Use local version if available
            source "$FUNCTIONS_DIR/$func"
        elif [ -f "$func_path" ]; then
            # Use downloaded version
            source "$func_path"
        else
            log_warn "Function file not found: $func"
        fi
    done
}

# Install Tailscale
install_tailscale() {
    local log_prefix="[TAILSCALE]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Installing Tailscale..."
    
    # Add Tailscale's package signing key and repository
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
    
    # Install Tailscale
    sudo apt update
    sudo apt install -y tailscale
    
    echo -e "\033[0;32m${log_prefix}\033[0m Tailscale installed successfully!"
    
    return 0
}

# Configure IP forwarding
configure_ip_forwarding() {
    local log_prefix="[IP-FORWARD]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Configuring IP forwarding..."
    
    echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
    echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    
    echo -e "\033[0;32m${log_prefix}\033[0m IP forwarding enabled for subnet routing"
    
    return 0
}

# Configure UFW firewall
configure_firewall() {
    local log_prefix="[FIREWALL]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Configuring firewall..."
    
    # Enable UFW
    sudo ufw --force enable
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow Tailscale
    sudo ufw allow 41641/udp
    
    # Allow forwarding for Tailscale interface
    sudo ufw route allow in on tailscale0
    sudo ufw route allow out on tailscale0
    
    echo -e "\033[0;32m${log_prefix}\033[0m Firewall configured for Tailscale"
    
    return 0
}

# Create helper scripts
create_helper_scripts() {
    local log_prefix="[HELPERS]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Creating helper scripts..."
    
    # Create tailscale management script
    sudo tee /usr/local/bin/ts-setup > /dev/null <<'EOF'
#!/bin/bash
# Tailscale setup helper script

echo "🔒 Tailscale Setup Helper"
echo "========================="
echo ""
echo "1. Start Tailscale (basic):"
echo "   sudo tailscale up"
echo ""
echo "2. Start Tailscale as subnet router:"
echo "   sudo tailscale up --advertise-routes=192.168.1.0/24"
echo ""
echo "3. Start Tailscale with exit node capability:"
echo "   sudo tailscale up --advertise-exit-node"
echo ""
echo "4. Check status:"
echo "   tailscale status"
echo ""
echo "5. Get your Tailscale IP:"
echo "   tailscale ip"
echo ""
echo "Note: Replace 192.168.1.0/24 with your actual subnet"
echo "After running 'tailscale up', visit the provided URL to authenticate"
EOF

    sudo chmod +x /usr/local/bin/ts-setup
    
    # Create network diagnostic script
    sudo tee /usr/local/bin/net-diag > /dev/null <<'EOF'
#!/bin/bash
# Network diagnostic script

echo "🌐 Network Diagnostics"
echo "====================="
echo ""
echo "=== Tailscale Status ==="
tailscale status
echo ""
echo "=== Tailscale IP ==="
tailscale ip
echo ""
echo "=== Network Interfaces ==="
ip addr show
echo ""
echo "=== Routing Table ==="
ip route show
echo ""
echo "=== Listening Ports ==="
ss -tulpn
echo ""
echo "=== Firewall Status ==="
sudo ufw status verbose
EOF

    sudo chmod +x /usr/local/bin/net-diag
    
    echo -e "\033[0;32m${log_prefix}\033[0m Helper scripts created: ts-setup, net-diag"
    
    return 0
}

# Main installation function
main() {
    echo "🔒 Starting Cyber Proxmox Tailscale VM setup (Modular)..."
    
    # Source all function modules
    log_step "Loading function modules..."
    source_functions
    
    # 1. System update and upgrade
    log_step "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    
    # 2. Configure timezone
    log_step "Configuring timezone..."
    configure_timezone "America/Montreal"
    
    # 3. Install network tools
    log_step "Installing network tools..."
    install_network_tools
    
    # 4. Install Tailscale
    log_step "Installing Tailscale..."
    install_tailscale
    
    # 5. Extend drive (LVM)
    log_step "Extending drive..."
    extend_lvm
    
    # 6. Generate SSH key
    log_step "Generating SSH key..."
    generate_ssh_key "rsa" "4096" "~/.ssh/id_rsa"
    
    # 7. Configure IP forwarding
    log_step "Configuring IP forwarding..."
    configure_ip_forwarding
    
    # 8. Configure firewall
    log_step "Configuring firewall..."
    configure_firewall
    
    # 9. Configure aliases
    log_step "Configuring aliases..."
    configure_aliases "tailscale"
    
    # 10. Create helper scripts
    log_step "Creating helper scripts..."
    create_helper_scripts
    
    # 11. Display installation summary
    display_summary
}

display_summary() {
    log_info "Tailscale VM installation completed successfully! 🎉"
    echo ""
    echo "📋 Summary:"
    echo "  ✅ System updated and upgraded"
    echo "  ✅ Timezone set to America/Montreal"
    echo "  ✅ Network tools installed"
    echo "  ✅ Tailscale installed"
    echo "  ✅ Drive extended (if LVM detected)"
    echo "  ✅ SSH key generated"
    echo "  ✅ IP forwarding enabled"
    echo "  ✅ Firewall configured"
    echo "  ✅ Network aliases added"
    echo "  ✅ Helper scripts created"
    echo ""
    echo "🕐 Current time: $(date)"
    echo "🌍 Timezone: $(timedatectl show --property=Timezone --value)"
    echo ""
    echo "🔑 Your SSH public key:"
    cat ~/.ssh/id_rsa.pub
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Logout and login to activate aliases"
    echo "  2. Run 'ts-setup' for Tailscale configuration help"
    echo "  3. Start Tailscale: sudo tailscale up"
    echo "  4. Visit the authentication URL provided"
    echo "  5. For subnet routing: sudo tailscale up --advertise-routes=YOUR_SUBNET"
    echo ""
    echo "💡 Useful commands:"
    echo "  ts-setup      - Tailscale setup helper"
    echo "  net-diag      - Network diagnostics"
    echo "  tsstatus      - Tailscale status"
    echo "  tsip          - Your Tailscale IP"
    echo "  myip          - Show network interfaces"
    echo "  ports         - Show listening ports"
    echo ""
    echo "🔧 Test your installation:"
    echo "  tailscale version"
    echo "  sudo ufw status"
    echo "  ip route show"
    echo "  df -h"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
