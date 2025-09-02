#!/bin/bash

# Cyber Proxmox VM Installation Script
# Compatible with Ubuntu 24.04 Server
# This script will install Docker, extend drive, setup SSH keys, and configure aliases

set -e  # Exit on any error

echo "🚀 Starting Cyber Proxmox VM setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 1. System update and upgrade
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 2. Install Docker and Docker Compose
log_info "Installing Docker and Docker Compose..."

# Install dependencies
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine, CLI, containerd and Docker Compose plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Install standalone docker-compose binary for compatibility
log_info "Installing standalone docker-compose binary..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

log_info "Docker installation completed!"

# 3. Extend drive (LVM)
log_info "Extending drive space..."

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

# 4. Generate SSH key
log_info "Generating SSH key..."
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    log_info "SSH key generated at ~/.ssh/id_rsa"
else
    log_warn "SSH key already exists, skipping generation"
fi

# 5. Create Docker directory
log_info "Creating ~/docker/ directory..."
mkdir -p ~/docker
log_info "Directory ~/docker/ created"

# 6. Add myip alias
log_info "Adding myip alias..."
ALIAS_LINE="alias myip='function _myip(){ ip a | grep \${1:-10}; }; _myip'"

# Add to .bashrc if not already present
if ! grep -q "alias myip=" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Custom aliases" >> ~/.bashrc
    echo "$ALIAS_LINE" >> ~/.bashrc
    log_info "myip alias added to ~/.bashrc"
else
    log_warn "myip alias already exists in ~/.bashrc"
fi

# Add to current session
eval "$ALIAS_LINE"

# 7. Display installation summary
log_info "Installation completed successfully! 🎉"
echo ""
echo "📋 Summary:"
echo "  ✅ System updated and upgraded"
echo "  ✅ Docker and Docker Compose installed"
echo "  ✅ Drive extended (if LVM detected)"
echo "  ✅ SSH key generated"
echo "  ✅ ~/docker/ directory created"
echo "  ✅ myip alias added"
echo ""
echo "🔄 Please log out and log back in to use Docker without sudo"
echo "🔑 Your SSH public key:"
cat ~/.ssh/id_rsa.pub
echo ""
echo "💡 Test your installation:"
echo "  docker --version"
echo "  docker compose version"
echo "  docker-compose --version"
echo "  myip"
echo "  df -h"
