#!/bin/bash

# Cyber Proxmox Tailscale VM Installation Script
# Compatible with Ubuntu 24.04 Server
# This script will install Tailscale, configure subnet routing, and setup proxy capabilities

set -e  # Exit on any error

echo "🔒 Starting Cyber Proxmox Tailscale VM setup..."

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

# 1. System update and upgrade
log_step "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 2. Install essential network tools
log_step "Installing network utilities..."
sudo apt install -y \
    curl \
    wget \
    net-tools \
    iptables-persistent \
    ufw \
    htop \
    ncdu \
    tree \
    jq

# 3. Install Tailscale
log_step "Installing Tailscale..."

# Add Tailscale's package signing key and repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

# Install Tailscale
sudo apt update
sudo apt install -y tailscale

log_info "Tailscale installed successfully!"

# 4. Extend drive (LVM) - Same as Django script
log_step "Extending drive space..."

# Check if we're using LVM
if [ -e /dev/mapper/ubuntu--vg-ubuntu--lv ]; then
    log_info "LVM detected, extending logical volume..."
    
    # Get the main disk device (usually sda)
    MAIN_DISK=$(lsblk -no pkname /dev/mapper/ubuntu--vg-ubuntu--lv | head -1)
    PARTITION_NUM=$(lsblk -no name /dev/mapper/ubuntu--vg-ubuntu--lv | grep -o '[0-9]*$' | head -1)
    
    if [ -z "$PARTITION_NUM" ]; then
        PARTITION_NUM=3  # Default to partition 3 for Ubuntu LVM
    fi
    
    PARTITION="/dev/${MAIN_DISK}${PARTITION_NUM}"
    
    log_info "Extending partition ${PARTITION}..."
    
    # Extend the partition using parted
    sudo parted /dev/${MAIN_DISK} ---pretend-input-tty <<EOF
resizepart ${PARTITION_NUM}
100%
Yes
quit
EOF

    # Resize physical volume
    sudo pvresize ${PARTITION}
    
    # Extend logical volume
    sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    
    # Resize filesystem
    sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
    
    log_info "Drive extension completed!"
else
    log_warn "LVM not detected, skipping drive extension. You may need to extend manually."
fi

# 5. Generate SSH key
log_step "Generating SSH key..."
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    log_info "SSH key generated at ~/.ssh/id_rsa"
else
    log_warn "SSH key already exists, skipping generation"
fi

# 6. Configure IP forwarding for subnet routing
log_step "Configuring IP forwarding..."
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

log_info "IP forwarding enabled for subnet routing"

# 7. Configure UFW firewall
log_step "Configuring firewall..."

# Enable UFW
sudo ufw --force enable

# Allow SSH
sudo ufw allow ssh

# Allow Tailscale
sudo ufw allow 41641/udp

# Allow forwarding for Tailscale interface (will be configured after tailscale up)
sudo ufw route allow in on tailscale0
sudo ufw route allow out on tailscale0

log_info "Firewall configured for Tailscale"

# 8. Add network aliases
log_step "Adding network aliases..."

# myip alias (same as Django script)
MYIP_ALIAS="alias myip='function _myip(){ ip a | grep \${1:-10}; }; _myip'"

# Additional network aliases for Tailscale management
TAILSCALE_ALIASES="
# Tailscale aliases
alias ts='tailscale'
alias tsstatus='tailscale status'
alias tsip='tailscale ip'
alias tsroutes='tailscale status --peers'
alias netstat-listen='netstat -tlnp'
alias ports='ss -tulpn'
"

# Add to .bashrc if not already present
if ! grep -q "alias myip=" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Network aliases" >> ~/.bashrc
    echo "$MYIP_ALIAS" >> ~/.bashrc
    echo "$TAILSCALE_ALIASES" >> ~/.bashrc
    log_info "Network aliases added to ~/.bashrc"
else
    log_warn "Network aliases already exist in ~/.bashrc"
fi

# Add to current session
eval "$MYIP_ALIAS"

# 9. Create helper scripts
log_step "Creating helper scripts..."

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

log_info "Helper scripts created: ts-setup, net-diag"

# 10. Display installation summary
log_info "Tailscale VM installation completed successfully! 🎉"
echo ""
echo "📋 Summary:"
echo "  ✅ System updated and upgraded"
echo "  ✅ Network tools installed"
echo "  ✅ Tailscale installed"
echo "  ✅ Drive extended (if LVM detected)"
echo "  ✅ SSH key generated"
echo "  ✅ IP forwarding enabled"
echo "  ✅ Firewall configured"
echo "  ✅ Network aliases added"
echo "  ✅ Helper scripts created"
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
